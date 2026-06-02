package search

import "fmt"

type ProviderOptions struct{}

type ProviderFactory func(ProviderOptions) (Provider, error)

var providerFactories = map[string]ProviderFactory{}

func RegisterProvider(name string, factory ProviderFactory) {
	providerFactories[name] = factory
}

func NewProvider(name string, options ProviderOptions) (Provider, error) {
	if name == "" || name == "noop" {
		return NewNoopProvider(), nil
	}
	factory, ok := providerFactories[name]
	if !ok {
		return nil, fmt.Errorf("search provider %q is not available", name)
	}
	return factory(options)
}
