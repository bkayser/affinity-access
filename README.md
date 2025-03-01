First [set up the gcloud command line tool and authenticate with the project.](https://cloud.google.com/artifact-registry/docs/docker/authentication?_gl=1*ck2s1d*_ga*MTEwODAzOTc0LjE3MDg1NjE5MDE.*_ga_WH2QY8WWF5*MTcwOTIzODg5NC45LjEuMTcwOTIzOTE3Ni4wLjAuMA..&_ga=2.34531937.-110803974.1708561901).
This includes instructions for setting up the gcloud command line tool and authenticating with the registry on a Mac and Windows.

On linux, you can install the gcloud command line tool with:

    sudo snap install google-cloud-sdk --classic

### Using gcloud to access the registry

From each machine you intend to use for pushing (builds) or pulling (deployments) images, you will need to authenticate:

    gcloud auth login
    gcloud config set project schedule-downloader
    gcloud auth configure-docker us-west1-docker.pkg.dev
    gcloud config set run/region us-west1

### Setting up the Container Cloud Run service


1. Build your container image: If you haven't already, build your Docker image and push it to a container registry.

2. Deploy with gcloud: Use the following command:

```
gcloud run deploy schedule-downloader \
    --image us-west1-docker.pkg.dev/schedule-downloader/oo-registry/game-scheduler:latest \
    --region us-west1 \
    --allow-unauthenticated
```

`--allow-unauthenticated` makes your service publicly accessible. If you need authentication, omit this flag.


### Mapping a domain name


```
gcloud beta run domain-mappings create \
    --service schedule-downloader \
    --domain affinityaccess.live
```
