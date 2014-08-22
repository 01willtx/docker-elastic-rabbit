__author__ = 'e002678'
from datetime import datetime
from elasticsearch import Elasticsearch
import json, logging
import socket

def main():

    with open("mappings/inventoryindex/vehicle.json") as vehicle_mapping_data:
        vehicle_mapping = json.load(vehicle_mapping_data)
        vehicle_mapping_data.close()

    hostname = socket.gethostname()
    IP = socket.gethostbyname(hostname)

    # use to run locally
    #es = Elasticsearch([{"host": "192.168.59.103", "port": "9200"}])
    es = Elasticsearch([{"host": "localhost", "port": "9200"}])
    print IP
    # create an index in elasticsearch, ignore status code 400 (index already exists)
    #res = es.put_template(id="vehicletemplate",body=vehicle_template)

    res = es.indices.create(index='inventoryindex', ignore=400)
    res = es.indices.create(index='vehicleindex', ignore=400)
  #  print(res['created'])
    #
    #es.put_template(id="vehicleindex",body=vehicle_mapping)
    #es.index(index="vehicleindex", doc_type="vehicle", id=42, body={"vehicleKey": "1000", "makeId": 12})
    # but not deserialized
    #es.get(index="vehicleindex", doc_type="vehicle", id=42)['_source']

if __name__ == '__main__':
    main()
