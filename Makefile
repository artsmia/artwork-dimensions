test:
	rewatch *.rb test/*.rb -c 'ruby test/mia-dimensions.rb'

all:
	ruby -r ./mia-dimensions.rb -e "RedisMiaArtwork.project_all"

single:
	ruby -r ./mia-dimensions.rb -e "RedisMiaArtwork.new($(id)).save_dimension_files!"

clean:
	rm -rf svgs

deploy:
	s3cmd sync -P -r svgs/ s3://mia-dimensions/

volumes:
	ruby -r ./mia-dimensions.rb -e "RedisMiaArtwork.volume_elasticsearch" \
  > ../collection-elasticsearch/bulk/volumes.json


.PHONY: test all single clean deploy
