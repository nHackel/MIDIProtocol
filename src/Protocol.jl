export MIDIProtocol, MIDIProtocolParams

Base.@kwdef mutable struct MIDIProtocolParams <: ProtocolParams
  filename::Union{Nothing, String} = nothing
end 
MPIMeasurementProtocolParams(dict::Dict) = params_from_dict(MPIMeasurementProtocolParams, dict)

mutable struct SingingStepcraft
  robot::MPIMeasurements.StepcraftRobot
  velForNotes::Vector{Int64}
  notes::Vector{String}
  positionOnStage::Vector{Vector{typeof(1.0u"mm")}}

  function SingingStepcraft(rob::StepcraftRobot)
    #Hard coded...
    velForNotes = [1980 2097 2222 2354 2495 2643 2800 2967 3143 3330 3528 3737 3960]
    notes = ["60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72"] #See Midi.jl Documentation
    #notes = ["C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B" "c"] 
    if length(velForNotes) != length(notes)
      error("Length of velocity table and note table don't match!")
    end
    teachingToSingInTune(rob,velForNotes)
    return new(rob,velForNotes,notes)
  end
end

Base.@kwdef mutable struct MIDIProtocol <: Protocol
  name::AbstractString
  description::AbstractString
  scanner::MPIScanner
  params::MPIMeasurementProtocolParams
  biChannel::Union{BidirectionalChannel{ProtocolEvent}, Nothing} = nothing
  executeTask::Union{Task, Nothing} = nothing

  midiFile::Union{MIDIFile, Nothing} = nothing
  done::Bool = false
  cancelled::Bool = false
  stopped::Bool = false
  finishAcknowledged::Bool = false

  singingStepcraft::SingingStepcraft = nothing
end

requiredDevices(protocol::MIDIProtocol) = [StepcraftRobot]

function teachingToSingInTune(rob::StepcraftRobot,velForNotes::Vector)
  range = length(velForNotes)
  if range > 100
    error("Only 100 storage places to store velocities!")
  end
  for tone = 1:range
    stepcraftCommand(rob,"#G$tone,$(velForNotes[tone])")
  end
end

function _init(protocol::MIDIProtocol)
  protocol.midiFile = load(protocol.params.filename)
  protocol.singingStepcraft = SingingStepcraft(getRobot(protocol.scanner))
  moveToMiddle(getRobot(protocol.scanner)
  checkForPlayablity(protocol.midifile)
  # TODO Check if this file is something we can play
  # TODO setup notes in StepcraftRobot
end

function moveToMiddle(rob::StepcraftRobot)
  axisRange = rob.params.axisRange
  _moveAbs(rob,axisRange./2)
end

function timeEstimate(protocol::MIDIProtocol)
  # TODO return track time as string. ?In SECONDS?
  notes = getnotes(protocol.midiFile, 1)
  return String(Int64(round((notes[1].pos-(notes[end].pos+notes[end].duration))/1000))))
end

function enterExecute(protocol::MPIMeasurementProtocol)
  protocol.done = false
  protocol.cancelled = false
  protocol.stopped = false
  protocol.finishAcknowledged = false
end

function _execute(protocol::MIDIProtocol)
  @info "MIDI protocol started"
  if !isReferenced(getRobot(protocol.scanner))
    throw(IllegalStateException("Robot not referenced! Cannot proceed!"))
  end

  performMusic(protocol)

  put!(protocol.biChannel, FinishedNotificationEvent())
  while !(protocol.finishAcknowledged)
    handleEvents(protocol) 
    protocol.cancelled && throw(CancelException())
    sleep(0.05)
  end

  @info "MIDI protocol finished"
  close(protocol.biChannel)
end

function performMusic(protocol::MIDIProtocol)
  notes = getnotes(protocol.midiFile, 1)

  # TODO pseudocode-ish
  for note in notes
    playNote(protocol, note)

    notifiedStop = false
    handleEvents(protocol)
    protocol.cancelled && throw(CancelException())
    while protocol.stopped
      handleEvents(protocol)
      protocol.cancelled && throw(CancelException())
      if !notifiedStop
        put!(protocol.biChannel, OperationSuccessfulEvent(StopEvent()))
        notifiedStop = true
      end
      if !protocol.stopped
        put!(protocol.biChannel, OperationSuccessfulEvent(ResumeEvent()))
      end
      sleep(0.05)
    end
  end
end

function playNote(protocol::MIDIProtocol, note)
  # TODO Make some magic
  if(Int(note.pitch)

end

function cleanup(protocol::MIDIProtocol)
  # NOP
end

function stop(protocol::MIDIProtocol)
  protocol.stopped = true
end

function resume(protocol::MIDIProtocol)
  protocol.stopped = false
end

function cancel(protocol::MIDIProtocol)
  protocol.cancelled = true
end

function handleEvent(protocol::MIDIProtocol, event::ProgressQueryEvent)

end

handleEvent(protocol::MIDIProtocol, event::FinishedAckEvent) = protocol.finishAcknowledged = true

Base.@kwdef mutable struct A
  B::Int64
  C::Int64 = test(B)
end

function test(x::Int64)
  return x/2
end