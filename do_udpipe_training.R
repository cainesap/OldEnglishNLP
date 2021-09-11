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

