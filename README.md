<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->


<br />
<div align="center">

![alt text](https://images.ctfassets.net/orqped9h4wgz/702AZCEQGGZEMOpl4ZuxPk/1191d60014a9cd07f94ec9721782e6e5/lendingclubLogo.svg)

<h3 align="center">Lending Club dbt <-> postgres <-> Lightdash </h3>

  <p align="center">
    This is the dbt project with the Lending Club dataset, models and schema.
    <br />
    <a href="https://medium.com/@jvilleres3/real-world-analytics-exploring-lending-club-loans-c84a84fe0379"><strong>Explore the article here »</strong></a>
    <br />
    <i>Disclaimer: This was done as part of a data science capstone project dealing with financial technology. </i>
    <br />

  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installing-dbt-postgres">Installing dbt-postgres adapter</a></li>
        <li><a href="#setup-a-local-postgres-server">Setup a postgres server</a></li>
        <li><a href="#load-the-loans-dataset-into-the-postgres-database">Load loans data into postgres database</a></li>
        <li><a href="#initialise-your-dbt-project">Initialise your dbt project</a></li>
        <li><a href="#modify-your-dbt-models-and-schema">Modify your dbt models schema</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This is data science project delving into credit loans dataset. 

<a href="https://medium.com/@jvilleres3/real-world-analytics-exploring-lending-club-loans-c84a84fe0379"><strong>Explore the article here »</strong></a>


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Installing dbt-postgres

Use pip to install the adapter, which automatically installs dbt-core and any additional dependencies. Use the following command for installation:

```
python -m pip install dbt-postgres
```
<a href="https://docs.getdbt.com/docs/core/connect-data-platform/postgres-setup"><strong>Read more on dbt-postgres setup here »</strong></a>

### Setup a local postgres server

You can setup a local postgres server using docker-compose.

Here is the compose file.

```yml
services:
  db:
    image: postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: example
    volumes:
- pgdata:/var/lib/postgresql/data
 
volumes:
  pgdata:
 
  adminer:
    image: adminer
    restart: always
    ports:
      - 8080:8080
```

Here is the docker-compose command

```
docker-compose up --remove-orphans
```

<a href="https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/"><strong>Read more on postgres setup via docker-compose here »</strong></a>

### Load the loans dataset into the postgres database

Ensure that the connection strings are updated correctly. First create the raw
landing table, then load the dataset/loan.csv file into your local postgres setup.

```
psql -h localhost -U postgres -d postgres -f scripts/create_loans_table.sql
python scripts/load_db_data.py
```

### Data-quality controls

The project carries a loan-level data-quality control set: 26 controls
implemented as named dbt tests across `models/example/schema.yml`,
`models/example/sources.yml` and `tests/`. They run with the models:

```
dbt deps  --profiles-dir .
dbt build --profiles-dir .
```

The control register — what each control asserts, the dbt test that implements
it, the SQL an auditor can re-run, and the before/after result with row counts —
is in [docs/loan-data-qc-evidence.md](docs/loan-data-qc-evidence.md). The same
controls run in CI on every pull request (`.github/workflows/dbt-qc.yml`).

### Initialise your dbt project

This is the part where you initialise dbt project. 

In dbt Cloud or dbt Core, the commands you commonly use are:

```bash
dbt run # Runs the models you defined in your project
dbt build # Builds and tests your selected resources such as models, seeds, snapshots, and tests
dbt test # Executes the tests you defined for your project
```

<a href="https://docs.getdbt.com/docs/running-a-dbt-project/run-your-dbt-projects"><strong>Read more on running a dbt project here »</strong></a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Modify your dbt models and schema

dbt allows you to contextualise models and schema to make it easy for use in visualization.

Lightdash automatically recognises the metrics and dimensions, saving your business users valuable time in configuring their charts

```yml
version: 2
models:
  - name: my_loans_model
    description: My loans model
    columns:
      - name: id
        description: A unique LC assigned ID for the loan listing.
        tests:
          - unique
          - not_null
        meta:
          dimension:
            type: number
          metrics:
            number_of_loans:
              type: count
            number_of_unique_loans:
              type: count_distinct
      - name: member_id
        description: A unique LC assigned ID for the borrower member.
        meta:
          dimension:
            type: string
          metrics:
      - name: loan_amnt
        description: >-
          The listed amount of the loan applied for by the borrower. If at some
          point in time, the credit department reduces the loan amount, then it
          will be reflected in this value.
        meta:
          dimension:
            label: loan amount
            type: number
          metrics:
            total_loan_amnt:
              label: total loan amount
              description: >-
                The listed total amount of the loan applied for by the borrower.
                If at some point in time, the credit department reduces the loan
                amount, then it will be reflected in this value.
              type: sum
```


<!-- USAGE EXAMPLES -->
## Usage

Here is the resulting overview dashboard using Lightdash !

![alt text](https://miro.medium.com/v2/resize:fit:786/format:webp/1*6LpOPgRQEfigf8pC7CpUBw.png)



<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [ ] Update this repository to include Lightdash component

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

Claude - [www.medium/@jvilleres3](www.medium/@jvilleres3) - claude.analyst@outlook.com

Project Link: [https://github.com/jcdevilleres/dbt-postgres-demo](https://github.com/jcdevilleres/dbt-postgres-demo)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* 


<p align="right">(<a href="#readme-top">back to top</a>)</p>

