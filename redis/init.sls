redis_install:
  pkg.installed:
    - name: redis-server

redis_log:
  file.symlink:
    - name: /logs/redis.log
    - target: /var/log/redis/redis-server.log
    - force: True

redis_service:
  service:
    - name: redis-server
    - running
    - restart: True
    - watch:
      - file: /etc/redis/redis.conf

redis_conf:
  file.managed:
    - name: /etc/redis/redis.conf
    - source: salt://redis/files/redis.conf
    - template: jinja

