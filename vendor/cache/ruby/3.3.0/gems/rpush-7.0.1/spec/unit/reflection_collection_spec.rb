 require 'unit_spec_helper'

 describe Rpush do
   it 'yields reflections for configuration' do
     did_yield = false
     Rpush.reflect { did_yield = true }
     expect(did_yield).to eq(true)
   end
 end

 describe Rpush::ReflectionCollection do
   it 'dispatches the given reflection' do
     did_yield = false
     Rpush.reflect do |on|
       on.error { did_yield = true }
     end
     Rpush.reflection_stack[0].__dispatch(:error)
     expect(did_yield).to eq(true)
   end

   it 'raises an error when trying to dispatch and unknown reflection' do
     expect do
       Rpush.reflection_stack[0].__dispatch(:unknown)
     end.to raise_error(Rpush::ReflectionCollection::NoSuchReflectionError)
   end
 end
