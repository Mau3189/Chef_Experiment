require_relative 'spec_helper'
require 'aws-sdk'

describe AwsInstanceManager do

  subject(:manager) { AwsInstanceManager.new(config_path, endpoint) }

  let(:instance_double_id) { 'i-e366c3eb' }
  let(:tags) { Hash.new }
  let(:instances_list) { [] }
  let(:region_list) { {} }

  let(:instance_double) do
    instance = double(AWS::EC2::Instance)
    instance.stub(:tags) { tags }
    instance.stub(:id) { instance_double_id }
    instance
  end

  let(:config_path) { "config.yml" }
  let(:endpoint) { "ec2.us-west-2.amazonaws.com" }
  
  describe '#launch' do
    new_params = {
      name:              'New Instance',
      image_id:          'ami-6cc2a85c',
      instance_type:     'm1.small',
      count:             2,
      security_groups:   'default',
      key_name:          'DB_keypair',
      availability_zone: 'us-west-2a'
    }    
    
    default_params = {
      name:              nil,
      image_id:          'ami-1e3a502e',
      instance_type:     't1.micro',
      count:             1,
      security_groups:   'quicklaunch-1',
      key_name:          'DC_Keypair',
      availability_zone: 'us-west-2b'
    }
    
    new_params.each do |param, value|
      if param == :name
        before do
          allow_any_instance_of(AWS::EC2::InstanceCollection).to(
            receive(:create).and_return(instance_double)
          ) 
        end

        context "when the #{param} is #{value}" do
          it "sets the name to #{value} after creating the instance" do
            manager.launch({param => value})
            expect(instance_double.tags['Name']).to eq value
          end
        end
        
        context "when the #{param} is not specified" do
          it "does NOT set the name after creating the instance" do
            manager.launch()
            expect(instance_double.tags).to be_empty
          end
        end
      else
        context "when the #{param} is #{value}" do
          let(:create_params) do
            create_params = default_params.dup
            create_params.delete(:name)
            create_params[param] = value
            create_params
          end
          
          it "calls InstanceCollection#create with #{value}" do
            expect_any_instance_of(AWS::EC2::InstanceCollection).to(
              receive(:create)
                .with(create_params)
                .and_return(instance_double)
            )
            manager.launch({param => value})
          end
        end
        
        context "when the #{param} is not specified" do
          let(:create_params) do
            create_params = default_params.dup
            create_params.delete(:name)
            create_params
          end
          
          it "calls InstanceCollection#create with #{default_params[param]}" do
            expect_any_instance_of(AWS::EC2::InstanceCollection).to(
              receive(:create)
                .with(create_params)
                .and_return(instance_double)
            )
            manager.launch()
          end
        end
      end
    end

    it 'returns the id of the newly created instance' do
      allow_any_instance_of(AWS::EC2::InstanceCollection).to(
        receive(:create).and_return(instance_double)
      )
      expect(manager.launch()).to eq instance_double_id
    end
  end # launch

  describe 'methods applied to an instance' do
    before do
      allow_any_instance_of(AWS::EC2).to(
        receive(:instances).and_return({instance_double_id => instance_double})
      )
    end

    describe '#stop' do
      it "calls Instance#stop for the instance with the ID indicated" do
        expect(instance_double).to(receive(:stop))
        manager.stop(instance_double_id)
      end
    end # stop
    
    describe '#start' do
      it "calls Instance#start for the instance with the ID indicated" do
        expect(instance_double).to(receive(:start))
        manager.start(instance_double_id)
      end
    end # start
    
    describe '#terminate' do
      it "calls Instance#terminate for the instance with the ID indicated" do
        expect(instance_double).to(receive(:terminate))
        manager.terminate(instance_double_id)
      end
    end # terminate

    describe '#set_tags' do
      let(:new_tags) {
        {
          'Name'          => 'New Instance for ChefExp',
          'image'         => 'Amazon Linux',
          'instance_type' => 'T1 Small',
          'purpose'       => 'Server for Chef Automation Experiment'
        }
      }
    
      it "sets the instance's tags with the values pairs provided" do
        manager.set_tags(instance_double_id,new_tags)
        expect(instance_double.tags).to eq new_tags
      end
    end #set_tags
  end # methods applied to an instance
  
  describe 'methods applied to AWS class and EC2 instance' do
    describe '#list_instances' do
      it "returns a list of instances from the current AwsInstanceManager" do
        expect_any_instance_of(AWS::EC2).to(
          receive(:instances).and_return(instances_list)
        )
        manager.list_instances
      end
    end #list_instances
    
    describe '#list_instances_per_region' do
      it "returns a list of instances per region" do
        expect(AWS).to(
          receive(:regions).and_return(region_list)
        )
        manager.list_instances_per_region 
      end
    end #list_instances_per_region  
  end # methods applied to AWS class and EC2 instance
  
end
