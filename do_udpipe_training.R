# see https://bnosac.github.io/udpipe/docs/doc3.html
library(udpipe)

# on plato in /local/scratch/apc38/YCOE/

trainfile <- '/local/scratch/apc38/YCOE/data/train.conll'
devfile <- '/local/scratch/apc38/YCOE/data/dev.conll'
testfile <- '/local/scratch/apc38/YCOE/data/test.conll'

mod <- udpipe_train(file='ycoe_lemmatiser.udpipe', files_conllu_training=trainfile, files_conllu_holdout=devfile,
  annotation_tokenizer='default', annotation_tagger='default', annotation_parser='none')

mod  # check for errors

# reload
m <- udpipe_load_model('ycoe_lemmatiser.udpipe')

# error here with accuracy function
gof <- udpipe_accuracy(m, testfile, tokenizer="default", tagger="default", parser="none")

# [1] "Incorrect ID '1' of CoNLL-U line '1\tBe\tbe\tADP\tP\t_\t0\tcase\t_\tsentence1'!"

df <- udpipe_annotate(object=m, x="This is my sentence.", parser='none')
as.data.frame(df)

# annotate and evaluate with test file
testo <- read.delim(testfile, as.is=T, header=F)

# annotate with vertical (row by row) tokenization
testann <- udpipe_annotate(m, x=testo$V2, tokenizer='vertical', parser='none')
testann.df <- as.data.frame(testann)

# lemmatiser accuracy
sum(testann.df$lemma==testo$V3)
95943/189638
# 0.5059271

# remove punctuation (because tagged as NA)
isnotpunct <- testann.df$upos!='PUNCT'
testann.df.nopunct <- testann.df[isnotpunct,]
testo.nopunct <- testo[isnopunct,]
# and a random NA token
testann.df.nopunct <- testann.df.nopunct[-142977,]
testo.nopunct <- testo.nopunct[-142977,]

# check tokens match
sum(testann.df.nopunct$token==testo.nopunct$V2)

# tagging accuracy (XPOS)
sum(testann.df.nopunct$xpos==testo.nopunct$V5)
76123/183087
# 0.415775

# and UPOS
sum(testann.df.nopunct$upos==testo.nopunct$V4)
99874/183087
# 0.5455002
