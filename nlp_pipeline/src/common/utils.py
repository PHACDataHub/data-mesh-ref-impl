import json
import time

import numpy as np
import pandas as pd
from tabulate import tabulate


class NumpyFloatValuesEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.float32):
            return float(obj)
        return JSONEncoder.default(self, obj)


def to_json_str(o):
    return json.dumps(o, cls=NumpyFloatValuesEncoder)


def from_json_str(s):
    return json.loads(s)


def get_timestamp():
    return int(time.time())


def print_output(outputs):
    df = pd.DataFrame(outputs)
    prettyprint=tabulate(df, headers='keys', tablefmt='psql')
    print(prettyprint)
