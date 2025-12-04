# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    # Action middleware namespace for OrbStack provider.
    #
    # Contains action classes that implement Vagrant middleware operations
    # for OrbStack machine lifecycle management (create, halt, destroy, etc).
    #
    # @api public
    module Action
      # Action middleware autoload definitions
      autoload :Create, 'vagrant-orbstack/action/create'
    end
  end
end
