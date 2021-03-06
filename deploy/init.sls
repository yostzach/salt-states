include:
  - git
  - papertrail

{%- if salt['pillar.get']('deploy') %}
{%- if salt['pillar.get']('deploy:git') %}
{%- set target = salt['pillar.get']('deploy:target', '') %}

{%- if salt['pillar.get']('deploy:ssh_key') %}
{%- set key_path = '/root' %}
{%- if salt['pillar.get']('deploy:user') %}
  {%- set key_path = '/home/' + salt['pillar.get']('deploy:user') %}
{%- endif %}
create_ssh_dir:
  file.directory:
    - name: {{key_path}}/.ssh
    - mode: 0700
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
    - group: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
create_ssh_key:
  file.managed:
    - name: {{key_path}}/.ssh/id_rsa
    - contents_pillar: deploy:ssh_key
    - mode: 0400
    - makedirs: True
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
    - group: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
{%- endif %}

do_deploy:
  git.latest:
    - require:
      - pkg: git
    - name: {{ salt['pillar.get']('deploy:git', '') }}
    - rev: {{ salt['pillar.get']('deploy:branch', 'master') }}
    - submodules: true
  {%- if salt['pillar.get']('deploy:ssh_key') %}
    - identity: {{key_path}}/.ssh/id_rsa
  {%- endif %}
    - target: {{ target }}
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
  cmd.run:
    - name: git submodule init && git submodule sync && git submodule update
    - cwd: {{ target }}
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
  

{% if salt['pillar.get']('deploy:config') %}
write_config:
  file.managed:
    - name: {{ target }}/.env
    - source: salt://deploy/files/env
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
    - group: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
    - template: jinja
{%- endif %}

{%- if salt['pillar.get']('deploy:files') %}
{%- for filename, contents in salt['pillar.get']('deploy:files').items() %}
write_file_{{filename}}:
  file.managed:
    - name: {{target}}/{{filename}}
    - contents_pillar: deploy:files:{{filename}}
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
    - group: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
{%- endfor %}
{%- endif %}

{%- if salt['pillar.get']('deploy:logs') %}
symlink_logs:
  file.symlink:
    - name: /logs/{{ salt['pillar.get']('deploy:logs').split('/')[-1] }}
    - target: {{ salt['pillar.get']('deploy:logs') }}
    - require:
      - sls: papertrail
{%- endif %}



{% if salt['pillar.get']('deploy:cmd') %}
reboot_app:
  cmd.run:
    - name: {{ salt['pillar.get']('deploy:cmd') }}
    - cwd: {{ target }}
  {%- if salt['pillar.get']('deploy:user') %}
    - user: {{ salt['pillar.get']('deploy:user') }}
  {%- endif %}
{%- endif %}



{%- endif %}
{%- endif %}
