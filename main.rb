require 'green_shoes'
SH = 21

begin
  `modinfo`
rescue 'modinfo: ERROR:'
  'ERROR'
end

Shoes.app title: 'Eject', width: 550, height: 200 do
  para 'Input device', margin: 10
  @line = edit_line width: 400, margin: 10
  @item = button 'Disconnect', margin: 10
  @buttom = button 'Get list', margin: 10
  @buttom.click do
  @i = Thread.new do
      Shoes.app title: 'Device list', width: 900, height: 500 do
        Thread.current['tread'] = Thread.new do
          @edit_box = edit_box width: 900, height: 500
          @uuid = Array.new(SH)
          @uuid.map! do |item|
            item = `uuidgen - create a new UUID value`
          end
          loop do
            @edit_box.text = ''
            i = 5
            j = 0
            @array = Array.new(SH)
            Thread.current['array'] = @array
            @array[j] = {:name => '', :man => '', :guid => '', :device_part => '', :provider => '', :driver_name => '', :bus => '', :driver_file => ''}
            information = `lshw`
            information.split("\n").each do |item|
              if item.include?'description'
                if i > 0
                  i -= 1
                  next
                end
                @array[j][:name] = item.split(': ')[1]
              end
              if item.include?'vendor'
                if i > 0
                  i -= 1
                  next
                end
                @array[j][:man] = item.split(': ')[1]
              end
              if item.include?'bus info'
                if i > 0
                  i -= 1
                  next
                end
                @string = ''
                item.split(': ')[1].split('')[4..15].each { |item| @string += item }
                @array[j][:device_part] = @string.delete('@')
                @string = ''
                item.split(': ')[1].split('')[0..3].each { |item| @string += item }
                @array[j][:bus] = @string.delete('@')
              end
              if item.include?'configuration'
                item.split(' ').each do |line|
                  if line.include?'driver='
                    @array[j][:driver_name] = line.split('=')[1]
                    j += 1
                    @array[j] = {:name => '', :man => '', :guid => '', :device_part => '', :provider => '', :driver_name => '', :bus => '', :driver_file => ''}
                    break
                  end
                end
              end
            end
            @array.each do |device|
              if device[:name] == 'DVD-RAM writer'
                device[:driver_file] = 'ERROR'
                break
              end
              Dir.chdir("/sys/bus//#{device[:bus]}//devices/#{device[:device_part]}")
              info = IO.read('modalias')
              Dir.chdir("/sbin")
              info = `modinfo #{info}`
              device[:driver_file] = if info == ''
                                       'ERROR'
                                     else
                                       info.split("\n")[0].split(' ')[1]
                                     end
            end
            i = 0
            @array.delete(@array.last())
            @array.each do |item|
              item[:guid] = @uuid[i]
              i += 1
            end
            i = 1
            @array.each do |item|
              @edit_box.text += "Device # #{i}\n"
              @edit_box.text += "Name: #{item[:name]}\n"
              @edit_box.text += "Manufacturer: #{item[:man]}\n"
              @edit_box.text += "Provider: ASUSTeK Computer Inc.\n"
              @edit_box.text += "Device Path: #{item[:device_part]}\n"
              @edit_box.text += "Driver Name: #{item[:driver_name]}\n"
              @edit_box.text += "Sys file: #{item[:driver_file]}\n"
              @edit_box.text += "GUID: #{item[:guid]}\n"
              @edit_box.text += "Bus: #{item[:bus]}\n"
              i += 1
            end
            sleep 20
          end
        end
      end
    end
  end
  @item.click do
    name_device = @line.text
    @i['tread']['array'].each do |item|
      if item[:name] == name_device
        @time = item[:device_part]
        Dir.chdir("/sys/bus/#{item[:bus]}/drivers/#{item[:driver_name]}")
        `echo #{item[:device_part]} | sudo tee -a unbind`
        sleep 5
        `echo #{@time} | sudo tee -a bind`
        break
      end
    end
  end
end
