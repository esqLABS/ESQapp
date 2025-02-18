% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{.createOutputSchemaStringFromJson}
\alias{.createOutputSchemaStringFromJson}
\title{Create output simulation time string form output schema in json format}
\usage{
.createOutputSchemaStringFromJson(outputSchemaJson, schemaUnit = NULL)
}
\arguments{
\item{outputSchemaJson}{The 'OutputSchema' section from a Simulation of a json}

\item{schemaUnit}{The unit of the start time of the first interval
PK-Sim snapshot}
}
\value{
A named list, with 'Intervals' a string where each output interval is defined as
<start, end, resolution>, and intervals are separated by a ';',
and 'Unit' the unit of the start time of the first interval.
All values are transformed to 'Unit'.
}
\description{
Create output simulation time string form output schema in json format
}
