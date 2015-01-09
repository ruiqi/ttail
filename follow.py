#!/usr/bin/env python  
#coding=utf-8

import os
import time
from datetime import datetime, timedelta
import select
import subprocess
import shutil
import logging
import signal

import gevent
from gevent import monkey
monkey.patch_all()

import settings

logging.basicConfig(
    filename=settings.follow_log['filename'],
    level=settings.follow_log['level'],
    format='%(asctime)s %(levelname)s: %(message)s'
)

#points dir
points_dirname = settings.points_dirname
shutil.rmtree(points_dirname, ignore_errors=True)
os.mkdir(points_dirname)

#follow files
filenames = settings.filenames

followers = []

class Follower(object):
    def __init__(self, filename):
        self.filename = filename
        self.tail_p = subprocess.Popen(['tail', '-F', filename], bufsize=10240, stdout=subprocess.PIPE)
        self.fd = self.tail_p.stdout
        self.lines_count = 0
        self.pointname = open(os.path.join(points_dirname, '%s.point' %filename.replace('/', '__')), 'w')

    def follow(self):
        while select.select([self.fd], [], [])[0]:
            self.fd.readline()
            self.lines_count += 1

    def point(self):
        self.pointname.write('%s\n' %self.lines_count)
        logging.debug('%4d   %s' %(self.lines_count, self.filename))
        self.pointname.flush()
        self.lines_count = 0

#定时打点
def timer_point(seconds=10):
    start_time = datetime.now()
    loop_count = 0

    while True:
        for follower in followers: follower.point()

        loop_count += 1
        next_time = start_time + timedelta(seconds=seconds*loop_count)
        now_time = datetime.now()
        if next_time > now_time:
            time.sleep((next_time-now_time).seconds)
        else:
            time.sleep(1)

def main():
    threads = [gevent.spawn(timer_point)]
    for filename in filenames:
        follower = Follower(filename)
        followers.append(follower)
        threads.append(gevent.spawn(follower.follow))
    gevent.joinall(threads)

if __name__ == '__main__':
    main()
