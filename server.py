#!/usr/bin/env python3
from base64 import b64decode
from time import sleep

from dnslib import QTYPE, RR, A
from dnslib.server import BaseResolver, DNSServer

CHUNK_SIZE = 42


class Resolver(BaseResolver):
    def __init__(self):
        self.chunks = {}

    def write_to_file(self):
        ordered_chunks = [
            v for k, v in sorted(self.chunks.items(), key=lambda item: item[0])
        ]
        base64str = "".join(ordered_chunks).replace("-", "+").replace("_", "/") + "=="
        with open("output.bin", "wb") as output_file:
            output_file.write(b64decode(base64str))

        print("Result written to output.bin")

    def resolve(self, request, handler):
        qname = request.q.qname
        (chunk, chunk_id) = str(qname).removesuffix(".").removesuffix(".x").split(".")
        self.chunks[int(chunk_id)] = chunk

        if len(chunk) != CHUNK_SIZE:
            sleep(3)
            self.write_to_file()

        reply = request.reply()
        answser = RR(rname=qname, rtype=QTYPE.A, rclass=1, ttl=60, rdata=A("127.0.0.1"))
        reply.add_answer(answser)
        return reply


if __name__ == "__main__":
    resolver = Resolver()
    server = DNSServer(resolver, port=53, address="0.0.0.0", tcp=False)
    server.start()
    server.wait()
