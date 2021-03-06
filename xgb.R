library(data.table)
library(gpairs)
library(corrplot)
library(corrplot) 
library(gplots) 
library(xgboost)



trainX <- read.csv(file.choose())
testX <- fread("../input/test.csv")


gpairs(trainX[c(1:1000) , c(3:10)])



correlations = cor(trainX[c(1:1000) , c(3:20)])
corrplot(correlations, method=c("circle"))
corrplot(correlations, method=c("circle"), addCoef.col = "black")



trainY <- trainX$target
trainX <- trainX[,-c(1,2)]
testX <- testX[, -c(1), with = F]
names(trainX)
str(trainX)
dtrain <- xgb.DMatrix(data = as.matrix(trainX), label = as.matrix(trainY))

params <- list(booster = "gbtree",
               objective = "binary:logistic",
               eta=0.02,
               #gamma=80,
               max_depth=2,
               min_child_weight=1, 
               subsample=0.5,
               colsample_bytree=0.1,
               scale_pos_weight = round(sum(!trainY) / sum(trainY), 2))


set.seed(123)
xgbcv <- xgb.cv(params = params, 
                data = dtrain, 
                nrounds = 30000, 
                nfold = 5,
                showsd = F, 
                stratified = T, 
                print_every_n = 100, 
                early_stopping_rounds = 500, 
                maximize = T,
                metrics = "auc")


 cat(paste("Best iteration:", xgbcv$best_iteration))


set.seed(123)
xgb_model <- xgb.train(
  params = params, 
  data = dtrain, 
  nrounds = xgbcv$best_iteration, 
  print_every_n = 100, 
  maximize = T,
  eval_metric = "auc")


imp_mat <- xgb.importance(feature_names = colnames(trainX), model = xgb_model)
xgb.plot.importance(importance_matrix = imp_mat[1:30])



pred_sub <- predict(xgb_model, newdata=as.matrix(testX), type="response")
submission <- read.csv("../input/sample_submission.csv")
submission$target <- pred_sub
write.csv(submission, file="submission_XgBoost.csv", row.names=F)
