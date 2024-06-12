# ADR 004: Search Admin Sync
2023-10-30

## Context
As part GOV.UK site search improvements, there is a need to maintain the capability to manually override certain search behaviours using defined rules in exceptional circumstances only. Currently in the existing GOV.UK search, these are managed using the [Search Admin application](https://docs.publishing.service.gov.uk/repos/search-admin.html). Vertex AI Search provides an equivalent capability called [Serving Controls](https://cloud.google.com/generative-ai-app-builder/docs/configure-serving-controls). 

The existing rules in Search Admin are being audited and only those deemed essential will be carried forward as Serving Controls. Vertex AI Search results will be evaluated without controls and controls only introduced where absolutely neccessary.

Currently Serving Controls are an allowlisted feature in Vertex AI Search and there is no Console/UI experience to manage these and these can only be applied via Rest API requests. Vertex AI Search console management capability for serving controls is expected to become available in the future. However, there may be further benefits to retain Search Admin as the management source due to requirements for maintaining rules in the long tail scenarios not covered by GOV.UK Search migration, for commenting/auditing rules and for maintaining familiarity of experience and access controls for the current user base.

Search Admin best bets rules can be mapped to Serving Controls as follows:-

![Serving Control Mapping](images/004-search-admin-to-serving-control-mapping.drawio.svg)

This ADR covers the architectural approach to sync rules/controls between the existing Search Admin application and Vertex AI Search in the short term.

## Considered options
### Cloud Function
This approach treats the sync as a batch data migration/transformation/sync activity.

![Serving Control Sync](images/004-search-admin-to-serving-control-flow-functions.drawio.svg)

Search Admin rules can be either exported in CSV format or obtained from Search Admin in JSON format in a one off exercise or ongoing via an additional api.

Existing Serving Controls can also be obtained from Vertex AI Search via the list method of the controls endpoint

A Python based Cloud Function can take both sources, load into Pandas dataframes, transform the Search Admin rules into Serving Control format, perform a diff with existing serving controls and then push the differences to the create, patch, delete methods of the control API

The function can set to be triggered by Cloud Scheduler on a regular(daily) basis or also triggered on an "as required" basis.

This can all be orchestrated and provisioned via Terraform following the same model as used for event data and outlined in [adr-002](002-gcp-usage.md)

### Terraform
This approach treats the sync as a platform orchestration/provisioning activity.

![Terraform](images/004-search-admin-to-serving-control-flow-terraform.drawio.svg)

Search Admin rules can exported and stored in JSON format in source control (Github repo). One JSON file will exist per rule so as to permit granular state management of rules. 

The Terraform REST provider would be used to control the deployment of these files via the Vertex AI Search Serving Controls REST API methods.

This will result in each rule existing as a serperate terraform resource and the state of each rule being mantained and managed granularly by Terraform

### Search Admin Native Integration
This approach treates the sync as a transactional application integration activity

![Direct](images/004-search-admin-to-serving-control-flow-direct.drawio.svg)

The Search Admin Ruby application could be modified to be tightly coupled and natively interact with the Vertex AI Search serving control API to manage rules/controls on a transactional basis using the create, patch, delete methods.

Seperate instances of the Search Admin application would exist in the corresponding GOV.UK microservice stack. These would align with the corresponding Vertex AI Search services in the corresponding GCP environment projects.

The Ruby application would be augmented to interact directly with the API on triggering of the corresponding application actions on a rule by rule basis. This would follow the model used currently for integration with Elasticsearch/Opensearch

## Decision drivers
1. The expectations for volume and frequency of change of Search Admin rules/controls is expected to be a fraction of those required with the incumbent solution and are to be avoided as much as possible and only used in exceptional circumstances. The existing rules are being audited and will only be carried over if the default results in Vertex AI Search absolutely require overrides.
2. Vertex AI Search is expected to provide Console capability for serving control management in the near future which could replace the requirement for Search Admin management
3. There will remain some need of managing rules in the incumbent solution for long tail scenarios not in scope for GOV.UK Search/Vertex AI Search. Syncing the rules to Vertex AI Search should not impact on the incumbent solution and experience
4. The rule to serving control mapping follows a consistent pattern and mapping isn't overly complex
5. The volume of existing rules and associated attributes are low (in the 1000s) so could easily be handled in memory with Python/Pandas and doesn't require additional loading/staging with a big data solution such as BigQuery.
6. The pattern for data and platform orchestration with Cloud Function/Cloud Scheduler is already defined and being used for Event data ([adr-002](002-gcp-usage.md)) so requires only an extension to what is already in use
7. Addition of a Search Admin API to provide the existing controls in JSON format or to provide native integration directly via the Serving Controls API is seen as being a relatively simple addition to the Search Admin application which shouldn't impact incumbent functionality
8. Augmentation of the existing Search Admin application will mean that this remains in the existing GOV.UK microservice tech stack and not introduce additional GCP workloads beyond those deemed absolutely neccessary 
9. Direct integration will minimise the latency of Search Admin rules being introduced and them taking effect in Vertex AI Search results whereas batch data processing or terraform provisioning may lead to increased latency
10. Terraform Cloud pricing is based on a per resource pricing model which could mean granular management of rules as resources could have a significant cost impact with the expected rule volumes (1000s)
 

## Decision
TBC

## Status
In Discussion
