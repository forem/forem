#!/usr/bin/env ruby

$LOAD_PATH << '../lib'

$VERBOSE = true

require 'gtk'
require 'zip'

class MainApp < Gtk::Window
  def initialize
    super()
    set_usize(400, 256)
    set_title('rubyzip')
    signal_connect(Gtk::Window::SIGNAL_DESTROY) { Gtk.main_quit }

    box = Gtk::VBox.new(false, 0)
    add(box)

    @zipfile = nil
    @button_panel = ButtonPanel.new
    @button_panel.open_button.signal_connect(Gtk::Button::SIGNAL_CLICKED) do
      show_file_selector
    end
    @button_panel.extract_button.signal_connect(Gtk::Button::SIGNAL_CLICKED) do
      puts 'Not implemented!'
    end
    box.pack_start(@button_panel, false, false, 0)

    sw = Gtk::ScrolledWindow.new
    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    box.pack_start(sw, true, true, 0)

    @clist = Gtk::CList.new(%w[Name Size Compression])
    @clist.set_selection_mode(Gtk::SELECTION_BROWSE)
    @clist.set_column_width(0, 120)
    @clist.set_column_width(1, 120)
    @clist.signal_connect(Gtk::CList::SIGNAL_SELECT_ROW) do |_w, row, _column, _event|
      @selected_row = row
    end
    sw.add(@clist)
  end

  class ButtonPanel < Gtk::HButtonBox
    attr_reader :open_button, :extract_button
    def initialize
      super
      set_layout(Gtk::BUTTONBOX_START)
      set_spacing(0)
      @open_button = Gtk::Button.new('Open archive')
      @extract_button = Gtk::Button.new('Extract entry')
      pack_start(@open_button)
      pack_start(@extract_button)
    end
  end

  def show_file_selector
    @file_selector = Gtk::FileSelection.new('Open zip file')
    @file_selector.show
    @file_selector.ok_button.signal_connect(Gtk::Button::SIGNAL_CLICKED) do
      open_zip(@file_selector.filename)
      @file_selector.destroy
    end
    @file_selector.cancel_button.signal_connect(Gtk::Button::SIGNAL_CLICKED) do
      @file_selector.destroy
    end
  end

  def open_zip(filename)
    @zipfile = Zip::File.open(filename)
    @clist.clear
    @zipfile.each do |entry|
      @clist.append([entry.name,
                     entry.size.to_s,
                     (100.0 * entry.compressedSize / entry.size).to_s + '%'])
    end
  end
end

main_app = MainApp.new

main_app.show_all

Gtk.main
