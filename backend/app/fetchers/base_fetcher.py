class DataFetcher:
    def fetch_data(self, source):
        raise NotImplementedError

    def parse_data(self, raw_data):
        raise NotImplementedError

    def save_data(self, parsed_data):
        raise NotImplementedError
