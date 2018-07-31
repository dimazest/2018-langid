import json
import re
import unicodedata
import itertools
import subprocess
import tempfile

import pandas as pd
import numpy as np

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.base import BaseEstimator, ClassifierMixin, TransformerMixin
from sklearn.multioutput import MultiOutputEstimator


def text_without_entities(tweet_json):
    entities = tweet_json['entities'].values()
    indicies = list(itertools.chain.from_iterable((e['indices'] for e in es) for es in entities))

    text = list(tweet_json['text'])
    for start, end in indicies:
        length = end - start
        text[start:end] = [None] * length

    return ''.join(filter(None, text))


def read_tweetlid_json(f_name):
    labels = ['ca', 'en', 'es', 'eu', 'gl', 'pt', 'und', 'other']
    with open(f_name) as f:
        data = map(json.loads, f)
        data = [
            {
                'id': t['id'],
                'text': t['text'],
                'text_without_entities': text_without_entities(t),
                'tweetlid_lang': t['tweetlid_lang'],
                'amb': '/' in t['tweetlid_lang'],
                **{
                    lang: 0 for lang in labels
                },
                **{
                    lang: 1 #/ len(re.split('[/]|[+]', t['tweetlid_lang']))
                    for lang in re.split('[/]|[+]', t['tweetlid_lang'])
                }
            }
            for t in data
        ]

    data = pd.DataFrame.from_records(data, index='id')

    return (
        data[['text', 'text_without_entities']],
        data[labels]
    )


class TweetCleanup(BaseEstimator, TransformerMixin):
    def __init__(self, keep_entities=True):
        self.keep_entities = keep_entities

    def fit(self, X, y=None):
        return self
    
    def transform(self, X):
        if self.keep_entities:
            return X['text'].values
        else:
            return X['text_without_entities'].values
        

class TweetTransformer(BaseEstimator, TransformerMixin):
    def __init__(self, case=None,normal_form=None):
        self.case = case
        self.normal_form = normal_form

    def fit(self, X, y=None):
        return self
        
    def transform(self, X):
        if self.case == 'lowercase':
            X = map(str.lower, X)
        
        if self.normal_form is not None:
            X = map(lambda text: unicodedata.normalize(self.normal_form, text), X)
            
        return list(X)
    

class TweetClassifier(BaseEstimator, TransformerMixin):
    def __init__(
        self,
        analyzer='char', ngram_range=(2, 2), min_df=1, max_df=1.0,
        optimizer='rmsprop', activation='relu', epochs=20, batch_size=32,
        verbose=0,
    ):
        self.analyzer = analyzer
        self.ngram_range = ngram_range
        self.min_df = min_df
        self.max_df = max_df

        self.vect = CountVectorizer(
            analyzer=analyzer,
            ngram_range=ngram_range,
            lowercase=False,
            min_df=min_df,
            max_df=max_df,
        )
        
        self.optimizer = optimizer
        self.activation = activation
        self.epochs = epochs
        self.batch_size = batch_size
        self.verbose = verbose
        
    def fit(self, X, y=None):
        from keras.wrappers.scikit_learn import KerasClassifier

        X = self.vect.fit_transform(X)
        
        self.input_dim = X.shape[1]
        self.classifier = KerasClassifier(self.create_model)
        
        self.classifier.fit(
            X, y,
            epochs=self.epochs, batch_size=self.batch_size,
            verbose=self.verbose,
        )
        
        return self
        
    def transform(self, X):
        return self.classifier.predict_proba(self.vect.transform(X))
    
    def create_model(self):
#         import tensorflow as tf
#         from keras.backend.tensorflow_backend import set_session

#         config = tf.ConfigProto()
#         config.gpu_options.per_process_gpu_memory_fraction = 0.05
#         set_session(tf.Session(config=config))
        
        from keras.models import Sequential
        from keras.layers import Dense, Activation
        from keras.utils import multi_gpu_model
        
        from random import randrange
        
#         with tf.device('/device:GPU:{}'.format(randrange(4))):
        
        model = Sequential()
        model.add(Dense(32, input_dim=self.input_dim))
        model.add(Activation(self.activation))
        model.add(Dense(8))
        model.add(Activation('softmax'))

#             model = multi_gpu_model(model, gpus=4, cpu_merge=True, cpu_relocation=False)

        model.compile(
            optimizer=self.optimizer,
            loss='categorical_crossentropy',
            metrics=['accuracy'],
        )

        return model

    
class TweetThresholdLabeller(BaseEstimator, ClassifierMixin):
    def __init__(self, threshold=0.3):
        self.threshold = threshold

    def fit(self, X, y=None):
        return self
        
    def predict_proba(self, X):
        X = np.array(X)
        X[X < self.threshold] = 0

        return X / X.sum(axis=1)[:, np.newaxis]

    def predict(self, X):
        return self.predict_proba(X)


def runs_frame(grid):
    _keys = [k for k in grid.cv_results_.keys() if k.startswith('param_') or k == 'mean_test_score']
    runs = pd.DataFrame(
        {k: grid.cv_results_[k] for k in _keys},
    )

    runs.columns =[k_[len('param_'):] if k_.startswith('param_') else k_ for k_ in _keys]

    return runs


def tweetlid_run(y, pred):
    run = pd.DataFrame(pred, index=y.index, columns=y.columns)
    run_output = run.apply(lambda r: '+'.join(r.index[r]), axis='columns')

    return run_output


def tweetlid_eval_f1(tweetlid_run):
    with tempfile.NamedTemporaryFile(mode='w+t') as f:
        tweetlid_run.to_csv(f, sep='\t')
        f.flush()

        cp = subprocess.run(
            [
                'perl', 'eval_f1.pl',
                 '-r', 'TweetLID_corpusV2/tweetlid-training-tweets.tsv',
                '-d', str(f.name),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        
    return float(cp.stdout.strip().decode('ascii'))