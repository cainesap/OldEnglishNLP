# nb, max sentence length = 255 for udpipe
# identify long sentences and trim manually like this
# $ egrep "^256" data/*.conllu | less
# trimmed 2 sentences in 'cocura.o2'

# for udpipe: couldn't have 'lemmas' with more than 255 forms
# for sequence labeler: just removing bad lemmas (hyphens have empty tokens)
# discovered with subsetting and length of unique tokens per lemma
#largelemms <- c("name", "_", "-", "-;", "toponym", "demonym", "foreign_word")
badlemms <- c("-", "-;")

traindevtest <- data.frame()
trainfile <- '~/Corpora/YCOE/train.conll'
devfile <- '~/Corpora/YCOE/dev.conll' 
testfile <- '~/Corpora/YCOE/test.conll'
traintsv <- '~/Corpora/YCOE/train.tsv'
devtsv <- '~/Corpora/YCOE/dev.tsv' 
testtsv <- '~/Corpora/YCOE/test.tsv'

## if starting over
system(paste('rm', trainfile)); system(paste('rm', devfile)); system(paste('rm', testfile));
system('rm ~/Corpora/YCOE/*_*.conllu')

dirpath <- '~/Corpora/YCOE/'
files <- list.files(path=dirpath, pattern='.conllu$', full.names=T)
nfiles <- length(files)

for (f in 1:nfiles) {
  filein <- files[f]
  print(paste("Processing file", f, "of", nfiles, ":", filein))
  filemid <- gsub('.conllu', '_midpoint.conllu', filein)
  fileout <- gsub('.conllu', '_prepped.conllu', filein)
  filetsv <- gsub('.conllu', '_seqlabelling.tsv', filein)
  system(paste('egrep -v "^\\d+\\s+[A-Za-z0-9]+.*,.+:|^#"', filein, '| egrep "^\\d|^\\s*$" | egrep -v "(\\d+-){2,}" | egrep -v "^\\d+\\s+_" >',
    filemid))
  fin <- read.delim(filemid, header=F, as.is=T)
  arenas <- which(is.na(as.numeric(fin$V1)))
  fin$V1[arenas] <- 0
  sentid <- 0
  sentstart <- 1
  for (r in 1:nrow(fin)) {
    if (as.numeric(fin$V1[r])==1) {
#      print(paste('Found a sentence start in row:', r))
      if (r>1) {
#        print(paste('Adding it to V10 from row', sentstart, 'to', (r-1)))
        fin$V10[sentstart:(r-1)] <- paste0('sentence', sentid)
      }
      sentid <- sentid+1
      sentstart <- r
    }
  }
  fin$V10[sentstart:r] <- paste0('sentence', sentid)  # ensure final sentence has an id
  fint <- subset(fin, !V3 %in% badlemms)
  for (sid in unique(fint$V10)) {
    rowids <- which(fint$V10==sid)
    fint$V1[rowids] <- 1:length(rowids)
  }
  fint$V7 <- 0
  for (r in 1:nrow(fint)) {
    if ((r>1) & (fint$V1[r]==1)) {
      system(paste("echo '' >>", fileout))  # blank line at end of each sentence
      system(paste("echo '' >>", filetsv))
    }
    if (r==1) {
      write.table(fint[r,], file=fileout, quote=F, sep='\t', row.names=F, col.names=F)
#      write.table(fint[r,2:3], file=filetsv, quote=F, sep='\t', row.names=F, col.names=F)  # word and lemma for seqlab
      write.table(fint[r,c(2,4,3)], file=filetsv, quote=F, sep='\t', row.names=F, col.names=F)  # word, postag, lemma for seqlab-evolved
    } else {
      write.table(fint[r,], file=fileout, quote=F, sep='\t', row.names=F, col.names=F, append=T)
#      write.table(fint[r,2:3], file=filetsv, quote=F, sep='\t', row.names=F, col.names=F, append=T)  # word and lemma for seqlab
      write.table(fint[r,c(2,4,3)], file=filetsv, quote=F, sep='\t', row.names=F, col.names=F, append=T)  # word, postag, lemma for seqlab-evolved
    }
  }
  ntokens <- as.integer(system(paste('egrep -c "^\\d"', fileout), intern=T))
  train_dev_test <- sample(c('train', 'dev', 'test'), prob=c(.8, .1, .1), size=1)
  filename <- gsub('^.+/', '', fileout)
  lineout <- data.frame(filename, train_dev_test, ntokens)
  traindevtest <- rbind(traindevtest, lineout)
  if (train_dev_test=='train') {
    system(paste('cat', fileout, '>>', trainfile))
    system(paste('cat', filetsv, '>>', traintsv))
  } else if (train_dev_test=='dev') {
    system(paste('cat', fileout, '>>', devfile))
    system(paste('cat', filetsv, '>>', devtsv))
  } else {
    system(paste('cat', fileout, '>>', testfile))
    system(paste('cat', filetsv, '>>', testtsv))
  }
}

write.table(traindevtest, '~/Corpora/YCOE/train_dev_test_split_info.csv', row.names=F, sep=',')

# then zip up and copy to CL servers

# info about dataset sizes
sum(traindevtest$ntokens)
# 1259697
sum(subset(traindevtest, train_dev_test=='train')$ntokens)
# 944422
sum(subset(traindevtest, train_dev_test=='dev')$ntokens)
# 229008
sum(subset(traindevtest, train_dev_test=='test')$ntokens)
# 86267
sum(subset(traindevtest, train_dev_test=='dev')$ntokens) / sum(traindevtest$ntokens)
# 0.1817961
sum(subset(traindevtest, train_dev_test=='test')$ntokens) / sum(traindevtest$ntokens)
# 0.06848234
