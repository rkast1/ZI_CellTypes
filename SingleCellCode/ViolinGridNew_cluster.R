library(dplyr);library(tidyr);library(ggplot2);library(cowplot);library(Matrix);library(ggdendro);library(patchwork);library(Seurat)

ViolinGrid<-function(seur,genes,ident="seurat_clusters",useAllForClust=F,plotDend=T)
{
    dat=seur@assays$RNA@data
    dat=dat[genes,]
    dat=t(dat)   
    dat=as.data.frame(as.matrix(dat))
    dat["Cluster"]=seur@meta.data[,ident]
    dat<-dat %>% gather(Gene,logTPM,-Cluster)
    tab<-dat %>% group_by(Gene,Cluster) %>% summarise(Mean=mean(logTPM)) %>% spread(Cluster,Mean) %>% as.data.frame()
    rownames(tab)=tab[,1]
    tab=tab[,2:dim(tab)[2]]
    tab=t(tab)
    tab1=tab
    if(useAllForClust)
    {
        tab=AggregateExpression(seur,group.by=ident,slot="counts")[[1]]
        tab=data.frame(tab)
        for(i in colnames(tab)){
            tab[i]=log(1000000*tab[,i]/sum(tab[,i])+1)
        }
        tab=tab[seur@assays$RNA@var.features,]
        colnames(tab)=sub("^X","",colnames(tab))
        tab=t(tab)
        tab=scale(tab)
    }
    clust=hclust(dist(tab))
    clustOrd=clust$labels[order.dendrogram(as.dendrogram(clust))]
    dat["Cluster"]=factor(dat[,"Cluster"],clustOrd)
    q=ggdendrogram(clust, rotate = FALSE, size = 2)+xlab("")+theme(axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank())+theme(axis.title.y=element_blank(),axis.text.y=element_blank(),axis.ticks.y=element_blank())
    
    
    tab=t(tab1)
    clust=hclust(dist(tab))
    clustOrd=clust$labels[order.dendrogram(as.dendrogram(clust))]
    dat["Gene"]=factor(dat[,"Gene"],clustOrd)
    
    p=ggplot(dat,aes(y=logTPM,x=Cluster,fill=Gene))+facet_grid(Gene~.)+geom_violin(scale="width")+theme_cowplot()+theme(legend.position="none")+theme(axis.text.x = element_text(angle = 90, hjust = 1))
    if(plotDend)
    {
    	p=q/p+plot_layout(heights = c(1,6))
    }
    return(p)
}

