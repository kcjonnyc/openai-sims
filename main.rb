require_relative 'simulator'

simulator = Simulator.new

cast_members = simulator.create_cast
LoggerService.logger.info("Introducing your cast!")
simulator.print_cast(cast_members)

LoggerService.logger.info("Let the simulation begin!")
simulator.run_simulation(cast_members)
