require 'json'
require 'fileutils'

Vagrant.require_version ">= 1.6.0"

# Make sure the vagrant-ignition plugin is installed
required_plugins = %w(vagrant-ignition)

plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  if system "vagrant plugin install #{plugins_to_install.join(' ')}"
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "Installation of one or more plugins has failed. Aborting."
  end
end

ignition_file = "/tmp/config.ign"
box_name = "fedora-coreos"
CONFIG = File.join(File.dirname(__FILE__), "config.fcc")
CONFIG_IGN = File.join(File.dirname(__FILE__), "config.ign")

config = {
  :ignition => {
    :version => "3.0.0",
  },
  :passwd => {
    :users => [{
      :name => 'core',
      :sshAuthorizedKeys => ['ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuhsw87msJ5To2eCxbhqNdQ64WO9fkjbTeRbqMc3xLp ovidiu@ovidiu-Precision-7530'],
    }],
  },
}


module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.has_box?(box_name)
      if OS.windows?
        `vagrant box list`.match(/^#{box_name}\s+\(virtualbox,/)
      else
        `vagrant box list`.match(/^#{box_name}\s+\(libvirt,/)
      end
      
    end

    def OS.build_ign
      if OS.windows?
      else
        if !(system File.join(File.dirname(__FILE__), "build_fcc.sh")+" "+CONFIG+" "+CONFIG_IGN)
          
          exit 1
        end 
      end
      
    end


end



if !OS.has_box?(box_name)
  if OS.windows?
    if !(system "./build_box.bat #{box_name}")
      exit 1
    end
  else
    if !(system "./build_box.sh #{box_name}")
      exit 1
    end
  end
end

OS.build_ign


  


File.open(ignition_file, "w") { |file| file.puts JSON.generate(config)}
# Systems with SELinux will need to relabel the file.
# system("chcon system_u:object_r:virt_content_t:s0 #{ignition_file}")

Vagrant.configure("2") do |config|
  config.vm.box = 'fedora-coreos'
  config.ssh.private_key_path = '~/.ssh/id_ed25519'
  config.ignition.enabled = false
  config.vm.provider :libvirt do |lv|
    lv.memory = 1024
    lv.cpus = 1
    lv.qemuargs :value => '-fw_cfg'
    lv.qemuargs :value => "name=opt/com.coreos/config,file=#{CONFIG_IGN}"
  end
end
