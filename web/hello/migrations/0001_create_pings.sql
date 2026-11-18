CREATE TABLE pings (
    id INTEGER PRIMARY KEY,
    received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version TEXT NOT NULL,
    branch TEXT NOT NULL,
    country TEXT NOT NULL,
    region TEXT NOT NULL,
    continent TEXT NOT NULL,
    cloud_provider TEXT NOT NULL,
    project TEXT NOT NULL,
    test_groups INTEGER NOT NULL,
    test_cases INTEGER NOT NULL,
    asn INTEGER NOT NULL
);
