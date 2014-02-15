package wx;

import wx.Bitmap;
import wx.AssetInfo;
import haxe.io.Bytes;
import wx.WeakRef;
import sys.io.File;


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the NME command-line tools, based on the
 * contents of the *.nmml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */

class Assets 
{
   public static inline var UNCACHED = 0;
   public static inline var WEAK_CACHE = 1;
   public static inline var STRONG_CACHE = 2;

   public static var info = new Map<String,AssetInfo>();
   public static var cacheMode:Int = WEAK_CACHE;

   //public static var id(get_id, null):Array<String>;

   public static function getAssetPath(inName:String) : String
   {
      var i = getInfo(inName);
      return i==null ? null : i.path;
   }

   static function getResource(inName:String) : Bytes
   {
      var bytes = haxe.Resource.getBytes(inName);
      if (bytes==null)
      {
         trace("[nme.Assets] missing binary resource '" + inName + "'");
         for(key in info.keys())
            trace(" " + key + " -> " + info.get(key).path + " " + info.get(key).isResource );
         trace("---");
      }
      return bytes;
   }


   public static function trySetCache(info:AssetInfo, useCache:Null<Bool>, data:Dynamic)
   {
      if (useCache!=false && (useCache==true || cacheMode!=UNCACHED))
         info.setCache(data, cacheMode!=STRONG_CACHE);
   }

   public static function noId(id:String, type:String)
   {
      trace("[nme.Assets] missing asset '" + id + "' of type " + type);
      for(key in info.keys())
         trace(" " + key + " -> " + info.get(key).path );
      trace("---");
   }

   public static function badType(id:String, type:String)
   {
      var i = getInfo(id);
      trace("[nme.Assets] asset '" + id + "' is not of type " + type + " it is " + i.type);
   }

   public static function hasBitmapData(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && i.type==IMAGE;
   }

   public static function getInfo(inName:String)
   {
      var result = info.get(inName);
      if (result!=null)
         return result;
      var parts = inName.split("/");
      var first = 0;
      while(first<parts.length)
      {
         if (parts[first]=="..")
            first++;
         else
         {
            var changed = false;
            var test = first+1;
            while(test<parts.length)
            {
               if (parts[test]==".." && parts[test-1]!="..")
               {
                  parts.splice(test-1,2);
                  changed = true;
                  break;
               }
               test++;
            }
            if (!changed)
               break;
         }
      }
      var path = parts.join("/");
      if (path!=inName)
      {
         result = info.get(path);
      }
      return result;
   }

   /**
    * Gets an instance of an embedded bitmap
    * @usage      var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
    * @param   id      The ID or asset path for the bitmap
    * @param   useCache      (Optional) Whether to use BitmapData from the cache(Default: according to setting)
    * @return      A new BItmapData object
    */
   public static function getBitmapData(id:String, ?useCache:Null<Bool>):Bitmap
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"BitmapData");
         return null;
      }
      if (i.type!=IMAGE)
      {
         badType(id,"BitmapData");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }
 
      var data:Bitmap = null;
      if (i.isResource)
          data = Bitmap.fromBytes( getResource(i.path) );
      else
      {
         var bytes = File.getBytes(i.path);
         data = Bitmap.fromBytes(bytes);
      }
      trySetCache(i,useCache,data);
      return data;
   }

   public static function hasBytes(id:String):Bool
   {
      var i = getInfo(id);
      return i!=null;
   }


   /**
    * Gets an instance of an embedded binary asset
    * @usage      var bytes = Assets.getBytes("file.zip");
    * @param   id      The ID or asset path for the file
    * @return      A new ByteArray object
    */
   public static function getBytes(id:String,?useCache:Null<Bool>):Bytes
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Bytes");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var data:Bytes = null;
      if (i.isResource)
      {
         data = getResource(i.path);
      }
      else
      {
         data = File.getBytes(i.path);
      }

      trySetCache(i,useCache,data);

      return data;
   }

   public static function hasFont(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && i.type == FONT;
   }
   /**
    * Gets an instance of an embedded font
    * @usage      var fontName = Assets.getFont("font.ttf").fontName;
    * @param   id      The ID or asset path for the font
    * @return      A new Font object
    */
   public static function getFont(id:String,?useCache:Null<Bool>):Dynamic 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Font");
         return null;
      }
      if (i.type!=FONT)
      {
         badType(id,"Font");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var font:Dynamic = null;

      trySetCache(i,useCache,font);

      return font;
   }

   public static function hasSound(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && (i.type == SOUND || i.type==MUSIC);
   }
 

   /**
    * Gets an instance of an embedded sound
    * @usage      var sound = Assets.getSound("sound.wav");
    * @param   id      The ID or asset path for the sound
    * @return      A new Sound object
    */
   public static function getSound(id:String,?useCache:Null<Bool>):Dynamic
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Sound");
         return null;
      }
      if (i.type!=SOUND && i.type!=MUSIC)
      {
         badType(id,"Sound");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var sound:Dynamic = null;

      trySetCache(i,useCache,sound);

      return sound;
   }

   public static function getMusic(id:String,?useCache:Null<Bool>):Dynamic
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Music");
         return null;
      }
      if (i.type!=MUSIC)
      {
         badType(id,"Music");
         return null;
      }
      return getSound(id,useCache);
   }


   public static function hasText(id:String) { return hasBytes(id); }
   public static function hasString(id:String) {
     return hasBytes(id);
   }

   /**
    * Gets an instance of an embedded text asset
    * @usage      var text = Assets.getText("text.txt");
    * @param   id      The ID or asset path for the file
    * @return      A new String object
    */
   public static function getText(id:String,?useCache:Null<Bool>):String 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"String");
         return null;
      }

      if (i.isResource)
         return haxe.Resource.getString(i.path);

      var bytes = getBytes(id,useCache);

      if (bytes == null) 
         return null;

      var result = bytes.toString();
      //trace(result);
      return result;
   }
   public static function getString(id:String,?useCache:Null<Bool>):String 
   {
       return getText(id,useCache);
   }
}



