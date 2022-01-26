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

box_name = "fedora-coreos"

CONFIG = File.join(File.dirname(__FILE__), "config.rb")
CONFIG_FCC_S = File.join(File.dirname(__FILE__), "config_s.fcc")
CONFIG_IGN_S = File.join(File.dirname(__FILE__), "config_s.ign")
CONFIG_FCC_W = File.join(File.dirname(__FILE__), "config_w.fcc")
CONFIG_IGN_W = File.join(File.dirname(__FILE__), "config_w.ign")
CONFIG_LIBVIRT_NETWORK = File.join(File.dirname(__FILE__), "config_libvirt_network.xml")


# Defaults for config options defined in CONFIG
$num_instances = 1
$instance_name_prefix = "fcore"
$ip_base = "172.17.8"
$enable_serial_logging = false
$share_home = false
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$vb_cpuexecutioncap = 100
$shared_folders = {}
$forwarded_ports = {}

if File.exists?(CONFIG)
  require CONFIG
end



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
        if !(system File.join(File.dirname(__FILE__), "build_fcc.sh")+" "+CONFIG_FCC_S+" "+CONFIG_IGN_S)
          
          exit 1
        end
        if !(system File.join(File.dirname(__FILE__), "build_fcc.sh")+" "+CONFIG_FCC_W+" "+CONFIG_IGN_W)
          
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

file_names = [CONFIG_FCC_S, CONFIG_FCC_W]

file_names.each do |file_name|
  # replace placeholders in fcc file
  text = File.read(file_name+".template")
  new_contents = text.gsub(/\${server}/, "#{$ip_base}.101")
  new_contents = new_contents.gsub(/\${instance_prefix}/, "#{$instance_name_prefix}")
  
  # To write changes to the file, use:
  File.open(file_name, "w") {|file| file.puts new_contents}
end



OS.build_ign
# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_instances = ENV["NUM_INSTANCES"].to_i
end

  
# Use old vb_xxx config variables when set
def vm_gui
  $vb_gui.nil? ? $vm_gui : $vb_gui
end

def vm_memory
  $vb_memory.nil? ? $vm_memory : $vb_memory
end

def vm_cpus
  $vb_cpus.nil? ? $vm_cpus : $vb_cpus
end

# Systems with SELinux will need to relabel the file.
# system("chcon system_u:object_r:virt_content_t:s0 #{ignition_file}")

Vagrant.configure("2") do |config|
  config.vm.box = 'fedora-coreos'
  config.ssh.private_key_path = File.join(File.dirname(__FILE__), "id_ed25519")
  config.ignition.enabled = false

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  config.vm.provider :libvirt do |lv|
    text = File.read("#{CONFIG_LIBVIRT_NETWORK}.template")
    new_contents = text.gsub(/\${ip_base}/, "#{$ip_base}")
    # To write changes to the file, use:
    File.open(CONFIG_LIBVIRT_NETWORK, "w") {|file| file.puts new_contents}
  end

  config.trigger.before :up do |trigger|
      trigger.name = "Hello world"
      trigger.info = "I am running network provisioning before vagrant up!!"
      trigger.only_on = "#{$instance_name_prefix}-01"
      trigger.run = {inline: "bash -c 'virsh net-destroy --network ignit > /dev/null 2>&1 || true ; virsh net-undefine --network ignit > /dev/null 2>&1 || true; virsh net-create --file #{CONFIG_LIBVIRT_NETWORK}'"}
  end


  (1..$num_instances).each do |i|

    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        ["vmware_fusion", "vmware_workstation"].each do |vmware|
          config.vm.provider vmware do |v, override|
            v.vmx["serial0.present"] = "TRUE"
            v.vmx["serial0.fileType"] = "file"
            v.vmx["serial0.fileName"] = serialFile
            v.vmx["serial0.tryNoRxLoss"] = "FALSE"
          end
        end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        bb config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), host_ip: "127.0.0.1", auto_correct: true
      end

      $forwarded_ports.each do |guest, host|
        bb config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      ip = "#{$ip_base}.101"
      
      ["vmware_fusion", "vmware_workstation"].each do |vmware|
        config.vm.provider vmware do |v|
          v.gui = vm_gui
          v.vmx['memsize'] = vm_memory
          v.vmx['numvcpus'] = vm_cpus
        end
        config.vm.network :private_network, ip: ip
      
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
        vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vb_cpuexecutioncap}"]
        config.vm.network :private_network, ip: ip
      end

      config.vm.provider :libvirt do |lv|
        lv.nic_adapter_count = 10
        lv.memory = vm_memory
        lv.cpus = vm_cpus
        lv.qemuargs :value => '-fw_cfg'
        if i == 1
          #install k3s server 
          lv.qemuargs :value => "name=opt/com.coreos/config,file=#{CONFIG_IGN_S}"
          config.vm.network :private_network, ip: ip, mac: "52:54:00:fe:b3:c0", libvirt__network_name: "ignit"
          
        else
          #install k3s worker
          lv.qemuargs :value => "name=opt/com.coreos/config,file=#{CONFIG_IGN_W}"
          config.vm.network :private_network, libvirt__network_name: "ignit"
        end
        
      end

      if i != 1
        config.vm.provision "shell",
                            inline: "sudo systemctl restart k3s-agent.service"
      end
   
      
      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      # config.vm.synced_folder ".", "/opt/shared", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      # $shared_folders.each_with_index do |(host_folder, guest_folder), index|
      #   config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      # end

      config.vm.synced_folder '.', '/vagrant', disabled: true
      # if $share_home
      #   config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      # end
      
    end
  end
end
