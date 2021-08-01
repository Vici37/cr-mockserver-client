test:
	crystal spec --stats --error-trace

start-server:
	docker run -d --rm --name mockserver -p 1090:1090 mockserver/mockserver -logLevel INFO -serverPort 1090
