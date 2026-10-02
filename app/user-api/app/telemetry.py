"""Optional OpenTelemetry tracing. Enabled only when an OTLP endpoint is set,
so the service runs and tests pass with no collector present."""
import logging

logger = logging.getLogger("user-api.telemetry")


def init_tracing(app, service_name: str, endpoint: str | None) -> None:
    if not endpoint:
        logger.info("otel disabled (no OTEL_EXPORTER_OTLP_ENDPOINT)")
        return
    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint)))
        trace.set_tracer_provider(provider)
        FastAPIInstrumentor.instrument_app(app)
        logger.info("otel tracing enabled", extra={"extra_fields": {"endpoint": endpoint}})
    except Exception as exc:
        logger.error("otel init failed (continuing without tracing): %s", exc)
