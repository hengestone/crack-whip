# Test ruby Crossroads IO binding

require "ffi-rxs"

def assert(rc)
  raise "Last API call failed at #{caller(1)}" unless rc >= 0
end

link = "tcp://127.0.0.1:5555"


begin
  ctx = XS::Context.new
  s1 = ctx.socket(XS::XREQ)
rescue ContextError => e
  STDERR.puts "Failed to allocate context or socket"
  raise
end

s1.identity = 'socket1.xreq'
assert(s1.setsockopt(XS::LINGER, 100))


assert(s1.connect(link))

poller = XS::Poller.new
poller.register_writable(s1)
poller.register_readable(s1)

start_time = Time.now
@unsent = true
payload = nil


until @done do
  assert(poller.poll_nonblock)

  # send the message after 5 seconds

  puts "sending payload nonblocking"
  if payload.nil?
    payload = "Hello XS"
  end
  assert(s1.send_string(payload, XS::NonBlocking))
  @unsent = false

  # check for messages after 1 second
  sleep(1)
  poller.readables.each do |sock|
    puts sock.identity

    if sock.identity =~ /xrep/
      routing_info = ''
      assert(sock.recv_string(routing_info, XS::NonBlocking))
      puts "routing_info received [#{routing_info}] on socket.identity [#{sock.identity}]"
    else
      routing_info = nil
      received_msg = ''
      assert(sock.recv_string(received_msg, XS::NonBlocking))

      # skip to the next iteration if received_msg is nil; that means we got an EAGAIN
      next unless received_msg
      puts "message received [#{received_msg}] on socket.identity [#{sock.identity}]"
    end

    while sock.more_parts? do
      received_msg = ''
      assert(sock.recv_string(received_msg, XS::NonBlocking))

      puts "message received [#{received_msg}]"
    end

    puts "kick back a reply"
    assert(sock.send_string(routing_info, XS::SNDMORE | XS::NonBlocking)) if routing_info
    @done = true
  end

end

puts "executed in [#{Time.now - start_time}] seconds"

assert(s1.close)

ctx.terminate


