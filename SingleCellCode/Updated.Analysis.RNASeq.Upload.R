source("SharedVariable.R")
library(Seurat)
library(Signac)
source("load_Seurat.R")



lst=system("ls /stanley/levin_storage/jlevin/zi/nextseq_190426/*/s*/outs/filt* | grep : | sed 's/://g'",intern=T) ##list of 10X data to load


names(lst)=c("RNA1","RNA2","RNA3")

dat=Read10X(lst)

seur=dir10X(dat=dat)

seur<-SharedVariable(seur,minNum=0)

seur<-ScaleData(seur,features=seur@assays$RNA@var.features,vars.to.regress="nFeature_RNA")

seur<-RunPCA(seur,npcs=60)

seur<-RunUMAP(seur,dims=1:20)

seur<-FindNeighbors(seur,dims=1:20)

seur<-FindClusters(seur)



top=colSums(seur@assays$RNA@counts[grep("^mt-",rownames(seur@assays$RNA@counts)),])
bot=colSums(seur@assays$RNA@counts)
rat=top/bot
seur@meta.data["Mito"]=rat

top=colSums(seur@assays$RNA@counts[grep("^Rp[s,l]",rownames(seur@assays$RNA@counts)),])
bot=colSums(seur@assays$RNA@counts)
rat=top/bot
seur@meta.data["Ribo"]=rat


writeMM(seur@assays$RNA@counts,"Data/For_scrublet_RNA.txt")

system("python RunScrublet.py Data/For_scrublet_RNA.txt Data/Out_scrublet_RNA.txt")
lst<-scan("Data/Out_scrublet_RNA.txt")
seur@meta.data["scrub"]=lst

seur<-subset(seur,scrub<.4)


seur@meta.data["Cluster"]=as.numeric(as.character(seur@active.ident))+1

lst=rep("Inhibitory",20)
lst[c(14,18,19)]="Glia"
lst[c(11,16,1)]="Excitatory"

seur@meta.data["CellType"]=lst[seur@meta.data[,"Cluster"]]

saveRDS(seur,"Data/seur.RNA.all.cells.RDS")

seur=subset(seur,CellType=="Inhibitory")



seur<-SharedVariable(seur,minNum=0)

seur<-ScaleData(seur,features=seur@assays$RNA@var.features,vars.to.regress="nFeature_RNA")

seur<-RunPCA(seur,npcs=60)

seur<-RunUMAP(seur,dims=1:20)

seur<-FindNeighbors(seur,dims=1:20)

seur<-FindClusters(seur)

seur<-subset(seur,seurat_clusters!=16)
seur<-subset(seur,seurat_clusters!=13)
seur<-subset(seur,seurat_clusters!=6)

seur<-subset(seur,seurat_clusters!=17)

saveRDS(seur,"Data/seur.inhib.RNA.ZI.only.RDS")

seur<-SharedVariable(seur,minNum=0)

seur<-ScaleData(seur,features=seur@assays$RNA@var.features,vars.to.regress="nFeature_RNA")

seur<-RunPCA(seur,npcs=60)

seur<-RunUMAP(seur,dims=1:20)

seur<-FindNeighbors(seur,dims=1:20)

seur<-FindClusters(seur)
seur<-FindClusters(seur,resolution=.3)
seur<-FindClusters(seur,resolution=.1)
seur<-FindClusters(seur,resolution=.5)
seur<-FindClusters(seur,resolution=1.5)
seur@meta.data["level1"]=sub("^","1_",seur@meta.data[,"RNA_snn_res.0.1"])
seur@meta.data["level2"]=sub("^","2_",seur@meta.data[,"RNA_snn_res.0.3"])
seur@meta.data["level3"]=sub("^","3_",seur@meta.data[,"RNA_snn_res.0.8"])
seur@meta.data["level4"]=sub("^","3_",seur@meta.data[,"RNA_snn_res.1.5"])
saveRDS(seur,"Data/seur.inhib.RNA.ZI.only.RDS")

library(presto)
mrk=wilcoxauc(seur,"level4")
saveRDS(mrk,"presto.DE.RDS")

