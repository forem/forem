# Common tests
module CommonTests
  def test_creating_service_and_backend
    name        = "fastly-test-service-#{random_string}"
    service     = @fastly.create_service(:name => name)
    assert service
    assert_equal name, service.name
    tmp         = @fastly.get_service(service.id)
    assert tmp
    assert_equal name, tmp.name

    version     = service.version
    assert version

    settings    = @fastly.get_settings(service.id, version.number)
    assert settings
    assert_equal settings.service_id, service.id
    assert_equal settings.version.to_s, version.number.to_s

    default_ttl = settings.settings['general.default_ttl']
    settings    = version.settings
    assert settings
    assert_equal service.id, settings.service_id
    assert_equal version.number.to_s, settings.version.to_s
    assert_equal default_ttl, settings.settings['general.default_ttl']

    settings.settings['general.default_ttl'] = default_ttl = '888888888'
    settings.save!

    settings = version.settings
    assert_equal default_ttl, settings.settings['general.default_ttl'].to_s

    services = @fastly.list_services
    assert !services.empty?
    assert !services.select { |s| s.name == name }.empty?

    service = @fastly.search_services(:name => name)
    assert service
    assert name, service.name

    service = @fastly.search_services(:name => name, :version => version.number)
    assert services
    assert name, service.name

    version2    = @fastly.create_version(:service_id => service.id)
    assert version2
    assert_equal version.number.to_i + 1, version2.number.to_i

    version3 = version2.clone
    assert version3
    assert_equal version2.number.to_i + 1, version3.number.to_i

    number = version3.number.to_i

    backend_name = "fastly-test-backend-#{random_string}"
    backend = begin
      @fastly.create_backend(:service_id => service.id, :version => number, :hostname => 'localhost', :name => backend_name)
    rescue Fastly::Error
    end
    assert_nil backend

    backend = @fastly.create_backend(:service_id => service.id, :version => number, :address => '74.125.224.146', :name => backend_name)
    assert backend
    assert_equal backend.service_id, service.id
    # assert_equal backend.ipv4, '74.125.224.146'
    assert_equal backend.address, '74.125.224.146'
    assert_equal backend.port.to_s, '80'

    backend.address  = 'thegestalt.org'
    backend.port     = '9092'
    @fastly.update_backend(backend)
    backend          = @fastly.get_backend(service.id, number, backend_name)

    assert backend
    assert_equal 'thegestalt.org', backend.address
    # assert_equal backend.hostname, 'thegestalt.org'
    assert_equal '9092', backend.port.to_s

    domain_name = "fastly-test-domain-#{random_string}-example.com"
    domain  = @fastly.create_domain(:service_id => service.id, :version => number, :name => domain_name)
    assert domain
    assert_equal domain_name, domain.name
    assert_equal service.id, domain.service.id
    assert_equal number.to_s, domain.version_number.to_s
    assert_equal number.to_s, domain.version.number.to_s

    domain.comment = 'Flibbety gibbet'
    domain.save!
    domain         = @fastly.get_domain(service.id, number, domain_name)
    assert_equal domain_name, domain.name
    assert_equal 'Flibbety gibbet', domain.comment

    director_name = "fastly-test-director-#{random_string}"
    director      = @fastly.create_director(:service_id => service.id, :version => number, :name => director_name)
    assert director
    assert_equal director_name, director.name
    assert_equal service.id, director.service.id
    assert_equal number.to_s, director.version_number.to_s
    assert_equal number.to_s, director.version.number.to_s

    assert director.add_backend(backend)
    # generated2  = version3.generated_vcl

    condition_name = "fastly-test-condition-#{random_string}"
    condition_statement = 'req.url ~ "^/foo"'
    condition = @fastly.create_condition(:service_id => service.id, :version => number, :name => condition_name, :statement => condition_statement, :type => 'REQUEST')
    assert condition
    assert_equal condition_name, condition.name
    assert_equal condition_statement, condition.statement

    cache_condition_name = "cache-#{condition_name}"
    cache_condition = @fastly.create_condition(:service_id => service.id, :version => number, :name => cache_condition_name, :statement => condition_statement, :type => 'CACHE')
    assert cache_condition
    assert_equal cache_condition_name, cache_condition.name
    assert_equal condition_statement, cache_condition.statement

    cache_setting_name = "fastly-cache-setting-#{random_string}"
    cache_setting = @fastly.create_cache_setting(:service_id => service.id, :version => number, :name => cache_setting_name, :ttl => 3600, :stale_ttl => 10_001, :cache_condition => cache_condition_name)
    assert cache_setting
    assert_equal cache_setting_name, cache_setting.name
    assert_equal '3600', cache_setting.ttl.to_s
    assert_equal '10001', cache_setting.stale_ttl.to_s
    assert_equal cache_condition_name, cache_setting.cache_condition

    gzip_name = "fastly-test-gzip-#{random_string}"
    gzip = @fastly.create_gzip(:service_id => service.id, :version => number, :name => gzip_name, :extensions => 'js css html', :content_types => 'text/html')
    assert gzip
    assert_equal gzip_name, gzip.name
    assert_equal 'text/html', gzip.content_types
    assert_equal 'js css html', gzip.extensions

    response_obj_name = "fastly-test-response-obj-#{random_string}"
    response_obj = @fastly.create_response_object(:service_id => service.id, :version => number, :name => response_obj_name, :status => 418, :response => "I'm a teapot", :content_type => 'text/plain', :content => 'short and stout')
    assert response_obj
    assert_equal response_obj_name, response_obj.name
    assert_equal '418', response_obj.status
    assert_equal "I'm a teapot", response_obj.response
    assert_equal 'text/plain', response_obj.content_type
    assert_equal 'short and stout', response_obj.content

    response_condition_name = "fastly-response-condition-#{random_string}"
    response_condition = @fastly.create_condition(:service_id => service.id, :version => number, :name => response_condition_name, :statement => condition_statement, :type => 'RESPONSE')
    header_name = "fastly-header-test-#{random_string}"
    header = @fastly.create_header(:service_id => service.id, :version => number, :name => header_name, :response_condition => response_condition.name, :ignore_if_set => 1, :type => 'response', :dst => 'http.Cache-Control', :src => '"max-age=301"', :priority => 10, :action => 'set', :regex => 'foo')
    assert header
    assert_equal header_name, header.name
    assert_equal response_condition.name, header.response_condition
    assert_equal '1', header.ignore_if_set.to_s
    assert_equal 'http.Cache-Control', header.dst
    assert_equal '"max-age=301"', header.src
    assert_equal 'set', header.action
    assert_equal('foo', header.regex)

    assert version3.activate!
    assert version3.deactivate!
    assert !@fastly.get_service(version3.service_id).version.active
    assert !@fastly.get_service(version3.service_id).version.active?
    assert version3.activate!
    assert @fastly.get_service(version3.service_id).version.active
    assert @fastly.get_service(version3.service_id).version.active?

    generated = version3.generated_vcl(:no_content => true)
    assert generated
    assert generated.content.nil?
    generated = version3.generated_vcl
    assert !generated.content.nil?
    assert generated.content.match(/\.port = "9092"/ms)

    assert version3.validate

    version3.deactivate!

    version4 = Fastly::Version.create_new(service.fetcher, :service_id => service.id)
    assert version4.number != version3.number
    assert @fastly.list_directors(:service_id => service.id, :version => version4.number).length == 0

    @fastly.delete_service(service)
  end

  def test_stats
    name        = "fastly-test-service-#{random_string}"
    service     = @fastly.create_service(:name => name)
    assert service
    assert_equal name, service.name
    tmp         = @fastly.get_service(service.id)
    assert tmp
    assert_equal name, tmp.name

    begin
      stats       = service.stats
    rescue Fastly::Error
    end
    assert stats.nil?

    stats       = service.stats(:all, :year => 2011, :month => 10)
    assert stats
    @fastly.delete_service(service)
  end

  def test_invoices
    name        = "fastly-test-service-#{random_string}"
    service     = @fastly.create_service(:name => name)
    assert service
    assert_equal name, service.name

    invoice     = service.invoice
    assert invoice
    assert invoice.regions
    assert_equal service.id, invoice.service_id

    invoice     = @fastly.get_invoice
    assert_equal Fastly::Invoice,  invoice.class

    year        = Time.now.year
    month       = Time.now.month

    invoice     = @fastly.get_invoice(year, month)
    assert_equal Fastly::Invoice,  invoice.class
    assert_equal year,  invoice.start.year
    assert_equal month, invoice.start.month
    assert_equal 1,     invoice.start.day
    assert_equal year,  invoice.end.year
    assert_equal month, invoice.end.month
    @fastly.delete_service(service)
  end
end
