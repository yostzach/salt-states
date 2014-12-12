{%- if salt['pillar.get']('papertrail') %}
{%- if salt['pillar.get']('papertrail:port') %}
{%- set port = salt['pillar.get']('papertrail:port') %}
get_certs:
  pkg.installed:
    - name: rsyslog-gnutls
  file.managed:
    - name: /etc/papertrail-bundle.pem
    - source: https://papertrailapp.com/tools/papertrail-bundle.pem
    - source_hash: md5=c75ce425e553e416bde4e412439e3d09
setup_rsyslog:
  file.append:
    - name: /etc/rsyslog.conf
    - text: |
        $DefaultNetstreamDriverCAFile /etc/papertrail-bundle.pem
        $ActionSendStreamDriver gtls
        $ActionSendStreamDriverMode 1
        $ActionSendStreamDriverAuthMode x509/name
        $ActionSendStreamDriverPermittedPeer *.papertrailapp.com
        *.* @logs.papertrailapp.com:{{ port }}
  service:
    - name: rsyslog
    - running
    - restart: True
    - watch:
      - file: /etc/rsyslog.conf
add_remote_syslog_config:
  file.append:
    - name: /etc/log_files.yml
    - text: |
      destination:
        host: logs.papertrailapp.com
        port: {{ port }}
        protocol: tls
      files:
setup_remote_syslog:
  archive:
    - extracted
    - name: /etc/remote_syslog
    - source: https://github.com/papertrail/remote_syslog2/releases/download/v0.13/remote_syslog_linux_amd64.tar.gz
    - source_hash: md5=e08f03664bb097cb91c96dd2d4e0f041
    - archive_format: tar
    - tar_options: v
    - if_missing /etc/remote_syslog
  file.symlink:
    - name: /usr/local/bin/remote_syslog
    - target: /etc/remote_syslog
  service:
    - name: remote_syslog
    - enable: True
    - restart: True
    - watch:
      - file: /etc/log_files.yml
{%- endif %}
{%- endif %}