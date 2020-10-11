
Step 1: install docker

yum install docker 

Step 2: docker pull  docker.elastic.co/elasticsearch/elasticsearch:7.9.2

Step 3:

Elasticsearch can be quickly started for development or testing use with the following command:

docker run -d  -p 9200:9200 -p 9300:9300 --name elasticsearch -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.9.2


Step 4:

Check the cluster health
curl http://127.0.0.1:9200/_cat/health

Output : [root@hostname sitecore]# curl http://127.0.0.1:9200/_cat/health
1602429354 15:15:54 docker-cluster green 1 1 0 0 0 0 0 0 - 100.0%
