library(Seurat)



##
##Gets shared variable genes between all batches
##
SharedVariable<-function(seur,x.low.cutoff=1,x.high.cutoff=5,minNum=3,batch="orig.ident",minCells=10)
{
batchs<-unique(seur@meta.data[,batch])

seur<-SetIdent(seur,value=batch)

vars<-c()

for(bat in batchs)
{
print(bat)
temp<-SubsetData(seur,cells=WhichCells(seur,idents=bat))
if(length(temp@active.ident)>minCells)
{
temp<-FindVariableFeatures(temp,selection.method="mean.var.plot",mean.cutoff=c(x.low.cutoff,x.high.cutoff))
vars<-c(vars,temp@assays$RNA@var.features)
}
print(" ")
}

print("Combine!")
vars<-table(vars)

genes<-names(vars)[vars>minNum]

print(length(genes))

seur@assays$RNA@var.features<-genes

return(seur)

}


