require 'set'

if ARGV.length != 1
  puts 'ruby verificador.rb [GR de entrada]'
  exit
end

gramatica = IO.readlines ARGV[0]
gramatica = gramatica[0].gsub(/\(|\)|\s+|\n/,"") #Retira parenteses
gramatica = gramatica.split("=") #Retira nome da gramatica
gramatica = gramatica[1].gsub(/\},/, "};") #Troca , por ;
gramatica = gramatica.gsub(/\{|}/,"") #Retira }
gramatica = gramatica.gsub(/\->/,"*")
gramatica = gramatica.split(";") #Separa a gramatica
gramatica[2] = gramatica[2].gsub("*",";")
gramatica[2] = gramatica[2].gsub(%r{\s*},";")
gramatica[2] = gramatica[2].gsub(";;","")
gramatica[2] = gramatica[2].gsub(";,;",",")
if gramatica[2][-1] == ";"
	gramatica[2][-1] = ""
end
if gramatica[2][0] == ";"
	gramatica[2][0] = ""
end
aux = gramatica[3]
gramatica[3] = gramatica[2].split ","
gramatica[2] = aux
gramatica[0].insert(0,'Q:')
gramatica[1].insert(0,'AF:')
gramatica[2].insert(0,'Si:')
gramatica[3].each do |linha|
	linha.insert(0,'T:')
end
for i in (1..gramatica[3].size-1)
	gramatica[3+i] = gramatica[3][i]
end
gramatica[3] = gramatica[3][0]

gramatica = gramatica.inject({}) do |h, rule|
	key, value = rule.chomp.split ':'
	value = '' if value.nil?
	case key
	when 'T'
		h[key] ||= []
		h[key] << value.split(';')
	when 'Si'
		h[key] = value
	else # A, Q
		h[key] = value.split(',').to_set
	end
	h
end

@states = gramatica['Q'] 
raise 'no states' if @states.empty?
@states.add('Fi')

@alphabet = gramatica['AF']
raise 'no alphabet' if @alphabet.empty?

@transitions = @states.inject({}) do |h, state|
	h[state] = {}
	h
end

gramatica['T'].each do |transition|
	state, input, next_state = transition
	raise "Estado invalido: #{state}" if not @states.member? state
	raise "Nao pertence ao alfabeto: #{input}" if not @alphabet.member? input and input != '#'
	@accept_states ||= Set.new
	@transitions[state][input] ||= Set.new
	if input == '#' and next_state == nil
		@accept_states << state
	else if input == '#'
		@accept_states << state
		@transitions[state][input] << next_state
		end
	end
	if next_state == nil #and input != '#'
		@accept_states.add('Fi')		
		@transitions[state][input].add('Fi')
	else if input != '#'
		@transitions[state][input] << next_state
		end
	end
end

@start_state = gramatica['Si']
raise "Estado inicial invalido: #{@start_state}" if not @states.member? @start_state

@accept_states.each do |state|
	raise "Estado nao e final: #{state}" if not @states.member? state
end

def reset
	@current_states = [ @start_state ].to_set
	read_empty
end

def read_input input
	unless input == '#'
		@current_states = next_states input
	end
	read_empty
end

def read_empty
	prev_states = @current_states
	@current_states |= next_states '#'
	if @current_states.size > prev_states.size
		read_empty
	end
end

def accept?(inputs)
	reset
	inputs.each do |input|
		read_input input.chomp
	end
	@current_states.any? { |q| @accept_states.member? q }
end

def next_states input
	@current_states.select { |state| !@transitions[state][input].nil? }.map { |state| @transitions[state][input] }.to_set.flatten
end

loop do
	reset
	print "\nPalavra: " 
	palavra = $stdin.gets.chomp.split("")
	if accept?(palavra)
		puts "\nSim\n"
	else
		puts "\nNao\n"
	end
end
