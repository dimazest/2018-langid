==========================================================================
This file describes the dataset used for the experimental validation in:

Tromp, E. & Pechenizkiy, M (2011) Graph-Based N-gram 
Language Identification on Short Texts. In Proc. of 
20th Annual Belgian-Dutch Conference on Machine Learning, 
Benelearn 2011.

If you use this dataset please refer to the paper.
==========================================================================

The folder contains six subfolders containing tweets in six different languages.
Tweets in a single subfolder are in the same language which is one of the following.

de_DE - German
en_UK - English
es_ES - Spanish
fr_FR - French
it_IT - Italian
nl_NL - Dutch

The files in each subfolder are named according to the scheme: x_y.txt
The x is the ID of one account, all messages with equal x are from one single account.
The y value is a unique ID for a single tweet of that account.

The following description is taken from the paper (Tromp & Pechenizkiy, 2011):

4.1. Dataset and Experiment Setup
The dataset was constructed from the social medium
Twitter. The Twitter API is used to extract messages
from accounts known to only contain messages of a
specific language. We do this for six languages and six
accounts per language. The six languages are German,
English, Spanish, French, Italian and Dutch. These
are languages we have sufficient knowledge of to iden-
tify. Moreover, including Spanish, French and Italian
presents a challenge as these languages contain a lot of
similar word extensions and trigram patterns. For ev-
ery language we have at least one account of a person
instead of an institution (such as BBC News). We as-
sume that each account has its own domain and hence
its own jargon that typically is not, or less often, used
in the other domains. When we indicate a domain
as random we mean that its messages are a mixture
of other domains. The rationale behind using six ac-
counts per language is that our experiments require
us to have dierent domains but incorporating tens or
hundreds of accounts is very laborious.

As a pre-processing step, we inspect our data as
in (Cavnar & Trenkle, 1994), removing messages that
contain multiple languages or bilingual terminology.
From each message we also deliberately remove links,
usernames preceded by an @ sign, term references pre-
ceded by a # sign or smilies such as :) and punctua-
tion. The rationale behind this is that we want to learn
a model on the language itself whereas these entities
are language-independent. Moreover, the use of Twit-
ter for our experiments is just to show an application
on short texts, learning Twitter-specific patterns con-
taining username or channel references is not desired.
The nal dataset contains 9066 labeled messages of at
most 140 bytes.

In both approaches we use trigrams (as suggested
in (Cavnar & Trenkle, 1994)) and the frequency based
measurement of (Ahmed et al., 2004).

References:

Tromp, E. & Pechenizkiy, M (2011) Graph-Based N-gram 
Language Identification on Short Texts. In Proc. of 
20th Annual Belgian-Dutch Conference on Machine Learning, 
Benelearn 2011

Ahmed, B., Cha, S., & Tappert, C. (2004). Language
identification from text using n-gram based cumula-
tive frequency addition. Proc. CSIS'04.

Cavnar, W., & Trenkle, J. (1994). N-gram-based text
categorization. Proc. 3rd Symp. on Document Anal-
ysis and Information Retrieval (SDAIR-94).