require'test_helper'

describe Fastly::ACLEntry do
  let(:fastly) { Fastly.new(api_key: 'secret') }
  let(:service) { fastly.create_service(name: 'acl_service') }
  let(:acl) { fastly.create_acl(service_id: service.id, version: 1, name: 'acl_group') }
  let(:acl_entry) { fastly.create_acl_entry(service_id: 'serviceid', acl_id: 'aclid', ip: '1.2.3.5') }
  let(:response) { nil }

  before do
    # Must be first
    stub_request(:any, /api.fastly.com/)
      .to_return(:status => 200, :body => response)

    # shared Service
    create_service_response_body = JSON.dump(
      'id' => 'aclserviceid',
      'name' => 'acl_service'
    )
    stub_request(:post, 'https://api.fastly.com/service')
      .to_return(:status => 200, :body => create_service_response_body)

    # shared ACL
    create_acl_response_body = JSON.dump(
      'id' => 'aclid',
      'name' => 'acl_group'
    )
    stub_request(:post, 'https://api.fastly.com/service/aclserviceid/version/1/acl')
      .to_return(:status => 200, :body => create_acl_response_body)

    # shared ACLEntry
    create_acl_entry_response_body = JSON.dump(
      'id' => 'aclentryid',
      'acl_id' => 'aclid',
      'ip' => '1.2.3.5',
      'service_id' => 'serviceid'
    )

    stub_request(:post, 'https://api.fastly.com/service/serviceid/acl/aclid/entry')
      .to_return(:status => 200, :body => create_acl_entry_response_body)
  end

  describe '#create_entry' do
    let(:response) do
      JSON.dump(
        'id' => 'aclentryid',
        'ip' => '1.2.3.5'
      )
    end

    it 'creates an ACL entry' do
      assert_equal acl_entry.ip, '1.2.3.5'
    end
  end

  describe '#get_entry' do
    let(:response) do
      JSON.dump(
        'id' => 'aclentryid',
        'ip' => '1.2.3.5'
      )
    end

    it 'gets an ACL entry' do
      assert_equal fastly.get_acl_entry('serviceid', 1, 'aclentryid').ip, acl_entry.ip
    end
  end

  describe '#update_entry' do
    let(:response) do
      JSON.dump(
        'id' => 'aclentryid',
        'ip' => '1.2.3.5',
        'subnet' => 8
      )
    end

    it 'updates an ACL entry' do
      acl_entry.subnet = 8
      fastly.update_acl_entry(acl_entry)
      assert_equal acl_entry.ip, '1.2.3.5'
      assert_equal acl_entry.subnet, 8
    end
  end

  describe '#delete_entry' do
    let(:response) { '{"status": "ok"}' }

    it 'deletes an ACL entry' do
      assert_equal fastly.delete_acl_entry(acl_entry), true
    end
  end

  describe '#list_entries' do
    let(:response) do
      JSON.dump(
        [
          {
            'id' => 'aclentryid',
            'ip' => '1.2.3.5'
          }
        ]
      )
    end

    it 'lists ACL entries' do
      assert_equal fastly.list_acl_entries.first.id, 'aclentryid'
    end
  end
end
