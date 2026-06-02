package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/agentwego/noema/services/api/internal/search"
	"github.com/agentwego/noema/services/api/internal/search/elastic"
)

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string, stdout io.Writer, stderr io.Writer) error {
	flags := flag.NewFlagSet("search-manifest", flag.ContinueOnError)
	flags.SetOutput(stderr)

	prefix := flags.String("prefix", "noema", "index name prefix")
	version := flags.String("version", "v1", "index schema version suffix")
	analyzer := flags.String("analyzer", elastic.AnalyzerNGram, "analyzer mode: ngram or ik")

	if err := flags.Parse(args); err != nil {
		return err
	}
	if *prefix == "" {
		return errors.New("prefix must not be empty")
	}
	if *version == "" {
		return errors.New("version must not be empty")
	}
	if *analyzer != elastic.AnalyzerNGram && *analyzer != elastic.AnalyzerIK {
		return fmt.Errorf("unknown analyzer %q: expected %q or %q", *analyzer, elastic.AnalyzerNGram, elastic.AnalyzerIK)
	}

	payload, err := elastic.ManifestJSON(search.IndexFamily{Prefix: *prefix, Version: *version}, *analyzer)
	if err != nil {
		return err
	}
	_, err = stdout.Write(append(payload, '\n'))
	return err
}
