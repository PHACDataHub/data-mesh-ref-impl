import json
import time


def to_json_str(o):
    return json.dumps(o, cls=NumpyFloatValuesEncoder)


def from_json_str(s):
    return json.loads(s)


def get_timestamp():
    return int(time.time())


class NumpyFloatValuesEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.float32):
            return float(obj)
        return JSONEncoder.default(self, obj)
