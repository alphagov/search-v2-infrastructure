# full_environment_without_events
This is a temporary module that copies or symlinks the more stable, non-event related resources from
the `full_environment` module. This allows us to aggressively iterate on the events ingestion code
but only have it deploy to a single (integration) environment.

TODO: This environment should be deleted and staging/prod should consume the main environment as
soon as events ingestion code is stable.
