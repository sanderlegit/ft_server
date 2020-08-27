ID=$(docker ps | grep "averheij/ft_server" | cut -d' ' -f1)
WORKDIR=/root

docker exec -it $ID bash $WORKDIR/set_autoindex_internal.sh $1
