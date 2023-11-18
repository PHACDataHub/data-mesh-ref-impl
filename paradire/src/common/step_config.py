import json
import os
import pathlib
import re

from dotenv import load_dotenv
import yaml


def print_config(step_name, step_config):
    print(f"STEP [{step_name}]")
    for k, v in step_config.items():
        print(f"\t - {k}: {v}", flush=True)

def substitute_environment_variables(content):
    load_dotenv()
    def replace(match):
        value = match.group().strip('${}').strip()
        return os.getenv(value)

    return re.sub(r'\$\{.+\}', replace, content)


def load_step_config(yaml_file, workflow_name, step_name):
    with open(yaml_file, mode="rt", encoding="utf-8") as f:
        substitute_yaml_content = substitute_environment_variables(f.read())
        yaml_config = yaml.safe_load(substitute_yaml_content)

        for workflow_name in yaml_config:
            for step in yaml_config[workflow_name]['steps']:
                if step_name not in step:
                    continue

                if 'params' in yaml_config[workflow_name] \
                    and 'step_settings' in yaml_config[workflow_name]['params']:
                    step_config = yaml_config[workflow_name]['params']['step_settings']
                else:
                    step_config = dict()

                step_config.update(step[step_name])
                print_config(step_name, step_config)
                return step_config

    return None


if __name__ == '__main__':
    import json
    import sys

    if len(sys.argv) < 5:
        print('Usage: python <path-to/>step_config.py <yaml_file> <workflow_name> <step_name> <env_file>')
        print('For example: python src/common/step_config.py workflow.yaml main dedup_by_id ../kafka_cluster/.env')
        exit(1)
    
    yaml_file, workflow_name, step_name, env_file = sys.argv[1:5]
    load_dotenv(dotenv_path=env_file)
    for name, value in os. environ. items():
        print("{0}: {1}". format(name, value))
    config = load_step_config(yaml_file, workflow_name, step_name)
    print(json.dumps(config))
