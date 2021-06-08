require "./io_uring"

# :nodoc:
struct Crystal::IoUringEvent < Crystal::Event
  enum Type
    Resume
    Timeout
    ReadableFd
    WritableFd
  end

  def initialize(@io_uring : Crystal::System::IoUring, @type : Type, @fd : Int32, &callback : Int32 ->)
    @callback = Box.box(callback)
  end

  def free : Nil
  end

  def delete : Nil
    if @type.timeout?
      @io_uring.timeout_remove(@callback)
    end
  end

  def add(time_span : Time::Span?) : Nil
    time_span = nil if time_span == Time::Span::ZERO

    case @type
    when .resume?, .timeout?
      if time_span
        @io_uring.timeout(time_span, @callback)
      else
        @io_uring.nop(@callback)
      end
    when .readable_fd?
      @io_uring.wait_readable(@fd, @callback, timeout: time_span)
    when .writable_fd?
      @io_uring.wait_writable(@fd, @callback, timeout: time_span)
    end
  end
end
