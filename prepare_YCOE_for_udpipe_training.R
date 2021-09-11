# nb, max sentence length = 255 for udpipe
# identify long sentences and trim manually like this
# $ egrep "^256" data/*.conllu | less
# trimmed 2 sentences in 'cocura.o2'

# and can't have 'lemmas' with more than 255 forms
# discovered with subsetting and length of unique tokens per lemma
largelemms <- c("name", "_", "toponym", "demonym", "foreign_word")

traindevtest <- data.frame()
trainfile <- '~/Corpora/YCOE/train.conll'
devfile <- '~/Corpora/YCOE/dev.conll' 
testfile <- '~/Corpora/YCOE/test.conll'

## if starting over
system(paste('rm', trainfile)); system(paste('rm', devfile)); system(paste('rm', testfile));
system('rm ~/Corpora/YCOE/*_*.conllu')

dirpath <- '~/Corpora/YCOE/'
files <- list.files(path=dirpath, pattern='.conllu$', full.names=T)
nfiles <- length(files)

for (f in 1:nfiles) {
  filein <- files[f]
  print(paste("Processing file", f, "of", nfiles, ":", filein))
  fileout <- gsub('.conllu', '_prepped.conllu', filein)
  filemid <- gsub('.conllu', '_midpoint.conllu', filein)
  system(paste('egrep -v "^\\d+\\s+[a-z]+,.+:|^#"', filein, '| egrep "^\\d|^\\s*$" | egrep -v "(\\d+-){2,}" >', filemid))
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
  fint <- subset(fin, !V3 %in% largelemms)
  for (sid in unique(fint$V10)) {
    rowids <- which(fint$V10==sid)
    fint$V1[rowids] <- 1:length(rowids)
  }
  fint$V7 <- 0
  for (r in 1:nrow(fint)) {
    if ((r>1) & (fint$V1[r]==1)) {
      system(paste("echo '' >>", fileout))  # blank line at end of each sentence
    }
    if (r==1) {
      write.table(fint[r,], file=fileout, quote=F, sep='\t', row.names=F, col.names=F)
    } else {
      write.table(fint[r,], file=fileout, quote=F, sep='\t', row.names=F, col.names=F, append=T)
    }
  }
  ntokens <- as.integer(system(paste('egrep -c "^\\d"', fileout), intern=T))
  train_dev_test <- sample(c('train', 'dev', 'test'), prob=c(.8, .1, .1), size=1)
  filename <- gsub('/Users/apc38/workspace/nlp-tools/marmot/data/', 'data/', fileout)
  lineout <- data.frame(filename, train_dev_test, ntokens)
  traindevtest <- rbind(traindevtest, lineout)
  if (train_dev_test=='train') {
    system(paste('cat', fileout, '>>', trainfile))
  } else if (train_dev_test=='dev') {
    system(paste('cat', fileout, '>>', devfile))
  } else {
    system(paste('cat', fileout, '>>', testfile))
  }
}

write.table(traindevtest, '~/Corpora/YCOE/train_dev_test_split_info.csv', row.names=F, sep=',')

# then zip up and copy to CL servers

# info about dataset sizes
sum(traindevtest$ntokens)
# 1261263
sum(subset(traindevtest, train_dev_test=='train')$ntokens)
# 965778
sum(subset(traindevtest, train_dev_test=='dev')$ntokens)
# 105847
sum(subset(traindevtest, train_dev_test=='test')$ntokens)
# 189638
sum(subset(traindevtest, train_dev_test=='dev')$ntokens) / sum(traindevtest$ntokens)
# 0.08392143
sum(subset(traindevtest, train_dev_test=='test')$ntokens) / sum(traindevtest$ntokens)
# 0.1503556
