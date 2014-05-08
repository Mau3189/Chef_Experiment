require 'aws-sdk'
require 'erb'

class AwsInstanceManager

  def initialize(config_path, endpoint)
    @config_path = config_path
    @endpoint = endpoint
    
    ### Create EC2 instance
    config_file = File.join(File.dirname(__FILE__), @config_path)
    loaded_data = YAML.load(ERB.new(File.read(config_file)).result)
    AWS.config(loaded_data)
    
    @ec2 = AWS::EC2.new(:ec2_endpoint => @endpoint)
  end
  
  def launch(args={})
    new_name          = args[:name]              || nil
    image_id          = args[:image_id]          || 'ami-1e3a502e'
    instance_type     = args[:instance_type]     || 't1.micro'
    count             = args[:count]             || 1
    security_groups   = args[:security_groups]   || 'quicklaunch-1'
    keypair_name      = args[:key_name]          || 'DC_Keypair'
    availability_zone = args[:availability_zone] || 'us-west-2b'

    ### Run and launch an EC2 instance
    instance = @ec2.instances.create(
      :image_id => image_id,
      :instance_type => instance_type,
      :count => count,
      :security_groups => security_groups,
      :key_name => keypair_name,
      :availability_zone => availability_zone)    
    
    instance.tags['Name'] = new_name unless new_name.nil?
    
    instance.id
  end
  
  def stop(id)
    @ec2.instances[id].stop
  end

  def start(id)
    @ec2.instances[id].start
  end

  def terminate(id)
    @ec2.instances[id].terminate
  end

  def set_tags(id, new_tags)
    @ec2.instances[id].tags.merge!(new_tags)
  end

end
