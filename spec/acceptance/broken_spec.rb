require 'spec_helper_acceptance'

describe 'a broken module' do
  specify 'should fail the puppet run' do
    pp = <<-EOS
      # test manifest
      class { 'drupal': }

      drupal::site { 'broken':
        core_version => '7.32',
        modules      => {
          'nonexistant' => '1.0',
        },
      }
    EOS

    apply_manifest(pp, :acceptable_exit_codes => [91])
  end
end
