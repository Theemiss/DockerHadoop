# DockerHadoop

Pseudo-distributed **Apache Hadoop 3.3.2** in a single Docker container - HDFS, YARN, and MapReduce history server - for local development, learning, and integration testing.

Runs as **root** with passwordless SSH on port **2122**, pre-formatted NameNode, and sample XML configs loaded into HDFS under `/user/root/input`.

> **Related repo:** [Hadoop-Docker](https://github.com/Theemiss/Hadoop-Docker) is a separate Holberton School environment checker (`hduser`-based). This repo is a standalone pseudo-distributed cluster image.

---

## What's inside

| Component | Version / notes |
|-----------|-----------------|
| Base image | Ubuntu (see `Dockerfile`) |
| Hadoop | 3.3.2 (Apache tarball) |
| Java | OpenJDK 8 |
| Python | 3 + `snakebite-py3` |
| Mode | Pseudo-distributed (single node) |
| Entrypoint | `bootstrap.sh` - starts SSH, DFS, YARN, MR history server |

**Config files:** `core-site.xml.template`, `hdfs-site.xml`, `mapred-site.xml`, `yarn-site.xml`

At container start, `HOSTNAME` replaces the `HOSTNAME` placeholder in `core-site.xml` (default `hdfs://<host>:9000`).

---

## Quick start

### Build

```bash
docker build -t dockerhadoop .
```

### Run (detached)

```bash
docker run -d \
  --name dockerhadoop \
  --hostname localhost \
  -p 9000:9000 \
  -p 8088:8088 \
  -p 9870:9870 \
  -p 19888:19888 \
  -p 2122:2122 \
  dockerhadoop
```

Or with Compose:

```bash
docker compose up -d --build
```

### Shell access

```bash
docker exec -it dockerhadoop /bin/bash
```

Inside the container:

```bash
hdfs dfs -ls /
yarn node -list
```

### Web UIs (after startup)

| UI | URL |
|----|-----|
| HDFS NameNode (Hadoop 3) | http://localhost:9870 |
| YARN ResourceManager | http://localhost:8088 |
| MapReduce JobHistory | http://localhost:19888 |

Port mappings match the `EXPOSE` list in the `Dockerfile`. If a UI does not load, check services with `jps` inside the container.

---

## Example: run a MapReduce job

```bash
docker exec -it dockerhadoop /bin/bash

hdfs dfs -mkdir -p /user/root
hdfs dfs -put $HADOOP_HOME/etc/hadoop/*.xml /user/root/input

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.2.jar grep \
  /user/root/input output 'dfs[a-z.]+'
```

---

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `HADOOP_HOME` | `/usr/local/hadoop` | Hadoop install path |
| `HOSTNAME` | Container hostname | Substituted into `core-site.xml` at boot |
| `ACP` | (empty) | Comma-separated URLs; extra JARs downloaded at startup |
| `HDFS_*_USER` / `YARN_*_USER` | `root` | Service users (see `Dockerfile`) |

---

## Repository layout

```
.
├── Dockerfile
├── bootstrap.sh          # Container entrypoint (SSH + Hadoop services)
├── start-hadoop.sh       # Alternate manual start script (not used by default CMD)
├── core-site.xml.template
├── hdfs-site.xml
├── mapred-site.xml
├── yarn-site.xml
├── ssh_config
├── docker-compose.yml
└── .github/workflows/    # CI: docker build on push
```

---

## Development notes

- **SSH:** Internal port `2122` (see `ssh_config` and `Dockerfile`).
- **Persistence:** Container filesystem is ephemeral unless you mount volumes for `/usr/local/hadoop` data dirs.
- **Security:** Intended for **local dev only** - runs Hadoop services as root with open SSH; do not expose to untrusted networks.
- **CI:** GitHub Actions builds the image on push to `main`. CircleCI / Mend configs were removed as unused templates.

---

## License

MIT - see [LICENSE](LICENSE).

Apache Hadoop is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

## Author

[Ahmed Belhaj](https://github.com/Theemiss)
