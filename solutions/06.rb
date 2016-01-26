module TurtleGraphics
  module Canvas
    class ASCII
      attr_accessor :array_of_symbols

      def initialize(array_of_symbols)
        @array_of_symbols = array_of_symbols
      end

      def length
        @array_of_symbols.size
      end

      def nth(number)
        @array_of_symbols[number]
      end

      def element_intensity(elem, arg, canvas)
        index = ((elem.to_f / find_the_highest(canvas)) * arg.length).ceil - 1
        print arg.nth(index)
      end

      def find_the_highest(canvas)
        canvas.flatten.sort[-1]
      end
    end

    class HTML
      attr_accessor :pixel_size

      def initialize(pixel_size)
        @pixel_size = pixel_size
      end

      def to_s
        @pixel_size.to_s
      end

      def intensity(element, canvas)
        element.to_f / find_the_highest(canvas)
      end

      def find_the_highest(canvas)
        canvas.flatten.sort[-1]
      end

      def header
        "<!DOCTYPE html>\n<html>\n<head>\n  <title>Turtle graphics</title>\n"
      end

      def style(arg)
        "  <style>
            table {
              border-spacing: 0;
            }

            tr {
              padding: 0;
            }

            td {
              width: " + arg.to_s + "px;
              height: " + arg.to_s + "px;

              background-color: black;
              padding: 0;
            }
          </style>
        </head>
        "
      end

      def intensity_table(canvas)
        "<body>
          <table>\n" << table(canvas) << " </table>
        </body>
        </html>"
      end

      def table(c)
        (c.map {|x| "<tr>\n" << table_help(x, c).to_s << "</tr>\n"}).to_s
      end

      def table_help(x, canvas)
        x.map{|y|
          "<td style=\"opacity:" << intensity(y, canvas).to_s << "></td>\"\n"}
      end
    end
  end

  class Turtle
    attr_reader :width, :height

    def initialize(width, height)
      @width, @height, @x, @y = width, height, 0, 0
      @canvas = Array.new(width) { Array.new(height, default = 0) }
      @canvas[0][0] += 1
      @orientation = :right
      @all_orientations = { :left => [0, -1], :right => [0, 1],
        :up => [-1, 0], :down => [1, 0] }
    end

    def draw(arg = nil)
      instance_eval(&Proc.new) if block_given?
      if (arg.class == TurtleGraphics::Canvas::ASCII)
        draw_ascii(arg, @canvas)
      elsif (arg.class == TurtleGraphics::Canvas::HTML)
        draw_html(arg, @canvas)
      end
    end

    def draw_ascii(arg, canvas)
      canvas.each do |row|
        puts row.map{ |x| arg.element_intensity(x, arg, canvas) }.join(" ")
      end
    end

    def draw_html(arg, canvas)
      html_text = ""
      html_text << arg.header << arg.style(arg) << arg.intensity_table(canvas)
      print html_text
    end

    def spawn_at(row, column)
      @x, @y = row, column
      @canvas[@x][@y] += 1
      @canvas[0][0] -= 1
    end

    def move
        if (@x + @all_orientations[@orientation][0] >= @width or
          @y + @all_orientations[@orientation][1] >= @height)
                move_help
        else
                @x += @all_orientations[@orientation][0]
                @y += @all_orientations[@orientation][1]
        end
        @canvas[@x][@y] += 1
    end

    def move_help
      case @orientation
      when :left
        @y = @width - 1
      when :right
        @y = 0
      when :up
        @x = @height - 1
      when :down
        @x = 0
      end
    end

    def turn_right
        look(@all_orientations.key(@all_orientations[@orientation].reverse))
    end

    def turn_left
        look(@all_orientations.key(@all_orientations[@orientation].reverse))
    end

    def look(orientation)
        @orientation = orientation
    end
  end
end