locals {
  # Extension settings are free-form, so they come in as JSON and are decoded here.
  extensions = [for name, extension in var.data_sources.extensions : {
    name              = name
    extensionName     = extension.extension_name
    streams           = extension.streams
    extensionSettings = extension.extension_settings == null ? null : jsondecode(extension.extension_settings)
    inputDataSources  = length(extension.input_data_sources) > 0 ? extension.input_data_sources : null
  }]
}
